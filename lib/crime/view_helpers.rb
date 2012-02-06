module Crime
  module ViewHelpers
    # WARD COLUMN METHODS
    def ward_count
      50
    end

    def ward_crime_hash(year)
      dataset = DB.fetch(Crime::QUERIES[:ward_crime_hash], :year => year)
      retain_in_cache(dataset.sql) do
        dataset.all
      end
    end

    def ward_crime_max(year)
      ward_crime_hash(year).map { |h| h[:crime_count] }.max
    end

    def ward_crime_columns(year)
      ward_crime_hash(year).map do |hash|
        if hash[:ward] != "0"
          crime_percentage = number_to_percentage(hash[:crime_count].to_f / ward_crime_max(year))

          {
            :ward => hash[:ward],
            :crime_count => hash[:crime_count],
            :crime_percentage => crime_percentage
          }
        end
      end.compact
    end

    # STATISTIC METHODS
    def statistic_crimes_by_ward(number)
      dataset = DB.fetch(QUERIES[:ward_crimes_per_year], :ward => number)
      retain_in_cache(dataset.sql) do
        dataset.all.sort do |a,b|
          a[:year] <=> b[:year]
        end
      end
    end

    def statistic_categories_by_ward_and_year(ward, year)
      dataset = DB.fetch(QUERIES[:ward_crimes_categories_per_year], :ward => ward, :year => year)
      retain_in_cache(dataset.sql) do
        dataset.all
      end
    end

    def year_comparison(crimes, year1, year2)
      data1 = crimes.detect { |c| c[:year].to_s == year1.to_s }[:crime_count_for_year]
      data2 = crimes.detect { |c| c[:year].to_s == year2.to_s }[:crime_count_for_year]

      diff = (data1.to_f / data2 * 100) - 100
      number_to_percentage(diff) / 100.0
    end

    # CALENDAR METHODS
    def ward_calendar_crime(ward, year)
      dataset = DB.fetch(Crime::QUERIES[:ward_crime_calendar], :ward => ward, :year => year)
      @ward_calendar_crime = retain_in_cache(dataset.sql) do
        dataset.all
      end
    end

    def ward_calendar_crime_max(year)
      75
#      dataset = DB.fetch(QUERIES[:crime_max_daily_year], :year => year)
#      retain_in_cache(dataset.sql) do
#        dataset.first[:max].to_f
#      end
#      DB.fetch(Crime::QUERIES[:crime_max_year], :year => year).first[:crime_count].to_f
    end

    def ward_calendar_detail(ward, year)
      @crime_max_year = ward_calendar_crime_max(year)
      @ward_calendar_detail ||= ward_calendar_crime(ward, year).map do |hash|
        crime_percentage = number_to_percentage(hash[:crime_count].to_f / @crime_max_year)
        {
          :date => hash[:occurred_at],
          :crime_count => hash[:crime_count],
          :crime_percentage => crime_percentage,
          :crime_max => @crime_max_year
        }
      end
    end
    
    def ward_stats_crimes_per_year(ward)
      DB.fetch(Crime::QUERIES[:ward_crimes_per_year], :ward => ward).all
    end

    def current_menu
      @current_menu
    end
    
    def current_menu_class(menu_name)
      return "current" if current_menu == menu_name
    end
    
    def format_number(number)
      integer_part = number.to_i
      integer_part_string = integer_part.to_s.reverse.gsub(/(\d{3}(?=(\d)))/, "\\1,").reverse
      
      "#{integer_part_string}"
    end

    def map_ward(number)
      parameters = {
        :sensor => "true", :size => "138x100",
        :path => "color:0xc10202aa|fillcolor:0xc1020211|weight:1|enc:ecp~FfwyuOs@fiBpx@iCd^vI|NmErP{K~FsVvGg`@rHaOnlAeAr@rVpHdB?~Lpp@ePX~MjiAeBxGoFpd@kDX~hAxc@gC?{Kju@?eBujDkyA`@?_z@_O??hRyS`@?nT}jA`@?nUu_D?Vzh@a~A`@YtWq`@?",
        :maptype => "roadmap", 
        :style => [
          "feature:road|visibility:off|saturation:-100",
          "feature:landscape|saturation:-100|lightness:75",
          "feature:transit|visibility:off",
          "feature:poi|saturation:-100|lightness:60",
          "feature:water|hue:0x00b2ff"
        ]
      }

      params_array = parameters.map do |name, value|
        if value.is_a?(Array)
          params_array = value.map do |item|
            "#{name}=#{item}"
          end
          params_array
        else
          "#{name}=#{value}"
        end
      end

      "http://maps.googleapis.com/maps/api/staticmap?#{params_array.flatten.join("&")}"
    end
  end
end
