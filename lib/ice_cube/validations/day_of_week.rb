module IceCube

  module Validations::DayOfWeek

    def day_of_week(dows)
      dows.each do |day, occs|
        occs.each do |occ|
          day = TimeUtil.sym_to_wday(day)
          validations_for(:day_of_week) << Validation.new(day, occ)
        end
      end
      clobber_base_validations :day, :wday
      self
    end

    class Validation

      attr_reader :day, :occ

      StringBuilder.register_formatter(:day_of_week) do |segments|
        str = I18n.t("ice_cube.on", sentence: segments)
        StringBuilder.sentence(str).strip
      end

      def initialize(day, occ)
        @day = day
        @occ = occ
      end

      def type
        :day
      end

      def build_s(builder)
        builder.piece(:day_of_week) << "#{StringBuilder.nice_number(occ)} #{I18n.t("date.day_names")[day]}"
      end

      def validate(step_time, schedule)
        wday = step_time.wday
        offset = (day < wday) ? (7 - wday + day) : (day - wday)
        wrapper = TimeUtil::TimeWrapper.new(step_time)
        wrapper.add :day, offset
        loop do
          which_occ, num_occ = TimeUtil.which_occurrence_in_month(wrapper.to_time, day)
          this_occ = (occ < 0) ? (num_occ + occ + 1) : (occ)
          break offset if which_occ == this_occ
          wrapper.add :day, 7
          offset += 7
        end
      end

      def build_hash(builder)
        builder.validations[:day_of_week] ||= {}
        arr = (builder.validations[:day_of_week][day] ||= [])
        arr << occ
      end

      def build_ical(builder)
        ical_day = IcalBuilder.fixnum_to_ical_day(day)
        # Delete any with this day and no occ first
        builder['BYDAY'].delete_if { |d| d == ical_day }
        builder['BYDAY'] << "#{occ}#{ical_day}"
      end

    end

  end

end
