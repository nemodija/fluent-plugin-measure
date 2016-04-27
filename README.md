# Fluent::Plugin::Measure

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
