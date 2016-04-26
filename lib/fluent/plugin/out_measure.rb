module Fluent
  class MeasureOutput < Output
    Plugin.register_output('measure', self)
  end
end
