# Weatherflow Tempest

> Get data from a Weatherflow weather station over the LAN.

Online docs found at [https://hexdocs.pm/weatherflow_tempest](https://hexdocs.pm/weatherflow_tempest).  
Code and bug reports are at [https://github.com/joshproehl/weatherflow_tempest](https://github.com/joshproehl/weatherflow_tempest).

Current Weatherflow UDP API version targeted is [143](https://weatherflow.github.io/Tempest/api/udp/v143/).

Supported devices:
- Air/Sky
- Tempest

## Installation

Add `weatherflow_tempest` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:weatherflow_tempest, "~> 0.1.0"}
  ]
end
```
and fetch your dependencies with
```
$ mix deps.get
```

Configure the PubSub output in your config.exs (or _env_.exs):

```elixir
config :weatherflow_tempest, :pubsub_name, MyApp.PubSub
```
If none is defined it will output to a pubsub named :weatherflow_tempest

## Usage

## License
MIT License

Copyright (c) 2021 Josh Proehl

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
