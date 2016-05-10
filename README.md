# Fluent::Plugin::Measure

[![Build Status](https://secure.travis-ci.org/nemonium/fluent-plugin-measure.png)](https://travis-ci.org/nemonium/fluent-plugin-measure)

Measure a processing number of time units.

## Installation

~~~
gem build fluent-plugin-measure.gemspec
gem install fluent-plugin-measure-0.0.1.gem
~~~

## Config

|param|description|type|required|default|
|---|---|---|---|---|
|path|出力先のファイルパス|string|no|nil|
|verbose|タグ単位の測定結果も出力するかどうか|bool|no|true|
|expire|計測結果を保持する期間を指定|integer|no|1800(sec)|

## Usage

~~~
<match next>
  type copy
  <store>
    ...
  </store>
  <store>
    type measure
    path /var/log/fluent/myapp1
  </store>
</match>
~~~

## Development

~~~
bundle install --path vendor/bundle
~~~

## Testing

~~~
rake test
~~~
