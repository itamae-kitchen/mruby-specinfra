##
## Specinfra Test
##

assert("Specinfra#hello") do
  t = Specinfra.new "hello"
  assert_equal("hello", t.hello)
end

assert("Specinfra#bye") do
  t = Specinfra.new "hello"
  assert_equal("hello bye", t.bye)
end

assert("Specinfra.hi") do
  assert_equal("hi!!", Specinfra.hi)
end
