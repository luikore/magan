# Introduction

Magan is compromisation between static parser generator and dynamic parser combinator. We can call it a *stanamic* parser generator. The generator can be used in either *static way*, that is, generate efficient parsers based on the grammar file, or a *dynamic way*, that is, change part of the parser with normal ruby code.

The grammar file shares many aspects with regular expressions, so you don't have to do much to switch mind sets when you rewrite your regexps into a parser.

The compiled parser is essentially (yet another) PEG parser. Rules are effectively compiled into ruby code and *Onigmo* regular expressions, which are compiled to bytecodes and are very fast (todo benchmarks to show how fast it is). In addition to the PEG thingies, Magan provides limited look backwards, limited non-greedy qualifiers, back references, and helpers to make parser building a lot easier. Existing parsers can also be extracted and reused in a modulized way.

# Building blocks

## Literals

### Strings

They are similar to ruby strings. Single quoted string has less escape rules, and double quoted string can be interpolated and you can use many escapes.

    hello = 'hello'
    world = "world \u1234"

### Char groups and char classes

Char groups are the same as in Onigmo. For example, to match a char that can be `a`, `b`, `c` or `d`

    ranged_chars = [a-d]

You can use the *double negation* trick to exclude some char from a char group

    alphabet_chars_except_w = [^w[^a-z]]

The whole list of backslashed, predefined char classes:

    any_char_except_newline = .
    word_char               = \w
    non_word_char           = \W
    digit_char              = \d
    non_digit_char          = \D
    hex_char                = \h
    non_hex_char            = \H
    space_char              = \s
    non_space_char          = \S

Char groups and classes can be combined just as in Onigmo

    a_or_digit_chars = [a\d]

Unicode char classes

    chinese_chars = \p{Han}
    any_char      = \p{Any}

There are two little differences from Onigmo char classes. The first one is, POSIX bracket expressions are not supported yet because I'm too lazy. The second one is, you can write `\p{Han,Hiragana}` instead of `[\p{Han}\p{Hiragana}]` --- saving a bit writing, yay!

### Anchors

The same as regexp anchors

    bol = ^
    eol = $
    begin_of_str = \A
    end_of_str = \z
    end_of_str_before_newline = \Z
    word_boundary = \b
    non_word_boundary = \B

`\G` (matching start position) is not supported.

## Capture variables

Captures can be used in inside blocks.

### Last-capture variable

    rule:var

### Aggregate variable

    rule::aggregate_var

## References

### Reference to rule

Our recursive parser is not complete without references. Here's a nonsense example that the rule `hello_world` references the rules `hello` and `world`:

    hello_world = hello ' ' world
    hello = "hello"
    world = "world"

As you can see in the above example, rules are declarative, they are not neccesary to be decalared before used as references.

### Reference to variable (A.K.A back reference)

The same syntax as the `\k` back references in Onigmo, here's an example for matching strings:

    string = ['"]:open .*? \k<open>

Note: we use the term **references** here in contrast to **literals**. A **literal** expression means it is fully composed without using any **references**. For example, `("a"+"b"+)?` is a literal but `a` is not.

## Look around anchors

We use the PEG notations here.

Look ahead (`&`)

    world = "world"
    hello = "hello" &world

Negative look ahead (`!`)

    identifier = !\d \w+

Look backward (`<&`) is available for expression of pure **literals**:

    <&("a"+)

But you can not put a **reference** inside a look backward

    hello = "hello"
    world = <&hello "world"

Negative look backward (`<!`), also only literals:

    we_are = <!\w \w+

## Qualifiers

We support the following qualifiers

    +
    *
    ?

Non-greedy qualifiers are literals-only (todo if i'm not lazy: make them available for references)

    +?
    *?

## Precedent branch

    /

## Block transformers

To access environment in the block

    @env.line
    @env.col
    @env.filename
    TODO: other env information

You have the responsibility to ensure they are idempotent --- which means for a certain position in the source code, the processor should return the same result no matter how many times it is called, and the side effects should not accumulate.

If you need a processor that is not idempotent, custom a helper.

## Helpers

Helpers are tools for building special or complex parsers from basic grammar expressions. Calling a helper looks like invoking a lambda. We provide several helpers to help reduce the amount of work:

    i['a']
    join[token, joiner]
    permutations[a, b, c, joiner]
    indent[]
    dedent[]
    samedent[]
    TODO: details and other indentation helpers

You can customize your helpers too. For example, if you have a `close` helper implemented like this:

    class MyParser
      extend Magan
      grammar File.read('a_syntax.magan')
      helper[:close] = -> backref_parser {
        # Note that a helper is a transformer for rules instead of results
        # if you want to transform results, use `map`
        backref_parser.map do |res|
          '(' => ')',
          '[' => ']',
          '{' => '}',
          '|' => '|',
          '<' => '>'
        end
      }
      compile :main
    end

You can use it like this:

    expr = [\(\[\{\|\<]:x content close[\k<x>]

Helper generated parsers are not cached by default, so you can apply dynamic non-idempotent logic here if you want. For example, to count how many times the parser is applied:

    helper[:count] = -> parser {
      parser.map do |res|
        @count ||= 0
        @count += 1
        res
      end
    }

# Debugging and Utils

## Error handling

Each rule is parsed into a method, `parse_xxx`, and the trace will guide you

## Testing

It's important to know what and how the parser does so we can tweak the grammar.

todo: Annotated source and expectations for unit testing

## Generate grammar graph and parsing animation

todo

# Misc

## Indentation sensitive parsing examples

todo

## Modules and dynamic parser variation interface

Change rule AST and re-generate new parsers.

todo

## Transform rules to make all branches inside literals

sell point, good for syntax coloring. todo

## Decent examples

todo

todo add simple examples inside this guide

## Editor support

todo

## A bit backgrounds on why we need a grammar syntax

Because:

+ Even the simplest internal DSL is a bit too verbose to show what the grammar does
+ Hard to make rules declarative
+ Have to modify symbols to fit host grammar
+ Can be used to generate other targets

## Left recursion

todo report error
todo experiment limited left recursion support

## Big-picture greedness

Let's look at two versions of a nonsense rule `a`. The first is:

    a = \s* "\n" \s*

The second is:

    a = a1 a2 a1
    a1 = \s*
    a2 = "\n"

What's the difference between the two? Well, the first can parse `" \n "` but the second fails at invoking `a2` at end of the string! This is a feature, not a bug (I hope). Qualifiers on literals makes the whole literal chain greedy and may do several backtracks to approach a longest match for the big picture. The *big-picture greedness* is the nature of NFA-based regular expression engines and makes many patterns easier to compose while can sometimes cause unexpected performance problems (for your information, Onigmo has atomic groups `(?>)` for the fix).

If you use PEG a lot, you already know the difference: the "greedness" expressed in PEG papers are usually only loyal to the atomic element before the qualifier, not the whole literal chain, it's *selfish*, not *cliquism*. If you need to defeature the *big-picture greedness*, just wrap parens around elements like this:

    a = (\s*) "\n" (\s*)

Then it behaves the same as the second one --- it never succeeds.

# License

BSD, see copying
