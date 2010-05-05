#!/usr/bin/ruby
require 'rubygems'
require 'mechanize'
require 'icalendar'
require 'active_support'

class String
  ACCENTS_MAPPING = {
     'E' => [200,201,202,203],
     'e' => [232,233,234,235],
     'A' => [192,193,194,195,196,197],
     'a' => [224,225,226,227,228,229,230],
     'C' => [199],
     'c' => [231],
     'O' => [210,211,212,213,214,216],
     'o' => [242,243,244,245,246,248],
     'I' => [204,205,206,207],
     'i' => [236,237,238,239],
     'U' => [217,218,219,220],
     'u' => [249,250,251,252],
     'N' => [209],
     'n' => [241],
     'Y' => [221],
     'y' => [253,255],
     'AE' => [306],
     'ae' => [346],
     'OE' => [188],
     'oe' => [189]
   }
   
   def removeaccents    
     str = String.new(self)
     String::ACCENTS_MAPPING.each {|letter,accents|
       packed = accents.pack('U*')
       rxp = Regexp.new("[#{packed}]", nil, 'U')
       str.gsub!(rxp, letter)
     }

     str
   end

end


class Parser
  def self.parse(url = "http://globoesporte.globo.com/Esportes/Futebol/TabelaJogos/Sao_Paulo/0,,EEJ0-9875,00.html")
    cal = Icalendar::Calendar.new
    
    year = Time.now.year
    
    agent = Mechanize.new
    agent.get(url)
    full_table = agent.page.search(".conteudo-resultados")
    full_table.children.each do |item|
      
      if item.name == "ul" && item[:class] == "lista2"
        item.children.first.children.search(".horario").text =~ /.*(\d\d\/\d\d).*/
        day = $1
        hour = item.children.first.search(".conteudo").children[3].text.gsub("\n", "").gsub("\t", "").split("|").map(&:strip).first
        desc = item.children.first.search(".conteudo").children[3].text.gsub("\n", "").gsub("\t", "").split("|").map(&:strip).last
        times = item.children.search(".time").map(&:text).map(&:strip)
        placar = item.children.search(".placar").text.strip
        
        initial_date = DateTime.strptime("#{day}/#{year} #{hour}", "%d/%m/%Y %H:%M") - 3.hours
        final_date = initial_date + 2.hours
        
        cal.event do
          dtstart initial_date
          dtend final_date
          summary "#{times.first} #{placar} #{times.last}"
          description "#{desc}"
        end
      end
    end
    puts cal.to_ical.removeaccents
  end
end
Parser.parse
