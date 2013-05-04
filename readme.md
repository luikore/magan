# Introduction

Magan is compromisation between static parser generator and dynamic parser combinator. We can call it a *stanamic* parser generator. The generator can be used in either *static way*, that is, generate efficient parsers based on the grammar file, or a *dynamic way*, that is, change part of the parser with normal ruby code.

The grammar file shares many aspects with regular expressions, so you don't have to do much to switch mind sets when you rewrite your regexps into a parser.

The compiled parser is essentially mostly (yet another) PEG parser. Rules are effectively compiled into ruby code and *Onigmo* regular expressions, which are compiled to bytecodes and are very fast (todo benchmarks to show how fast it is). In addition to the PEG thingies, Magan provides local look backwards, limited non-greedy quantifiers, back references, and helpers to make parser building a lot easier. Existing parsers can also be extracted and reused in a modulized way.

# Tutorial

todo

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

Capture variables are defined before a unit expression, and are used in blocks or back references.

### Last-capture variable

Normal captures

    var:rule1 var:rule2

In the above code, since two rules sharing the same capture variable, the capture of `rule2` just replaces the capture of `rule1`.

### Aggregate variable

Aggregate variables are put inside an array for repeated captures. For example

    (aggregate_var::rule1 rule2)*

## References

### Reference to rule

Here's a nonsense example that the rule `hello_world` invokes the rules `hello` and `world`:

    hello_world = hello ' ' world
    hello = "hello"
    world = "world"

As you can see in the example, rules are declarative, not neccesary to be decalared before used.

### Reference to variable (`\k`, A.K.A back reference)

The syntax is much like back references in Onigmo, here's an example for matching quoted strings:

    string = open:['"] .*? \k<open>

Note: we use the term **reference** here in contrast to **literal**. A **literal** expression means it is fully composed without using any **reference**. For example, `("a"+"b"+)?` is a literal but `a` is not.

## Look around anchors

We use the PEG notations here.

### Look ahead (`&`)

    world = "world"
    hello = "hello" &world

### Negative look ahead (`!`)

    identifier = !\d \w+

### Look backward (`<&`)

Only available for expression of pure **literals**:

    <&("a"+)

You can not put a **reference** inside a look backward, a compile error will be raised for the code below:

    hello = "hello"
    world = <&hello "world"

### Negative look backward (`<!`)

Also literals only:

    we_are = <!\w \w+

## Quantifiers

### Possesive

We support the following possessive quantifiers for all grammar expressions. The term "possessive" means the repeat count is fixed for self-longest-match, won't backtrack for less repeat counts.

    a+ # one or more a
    a* # zero or more a
    a? # zero or one a

They are the same as "greedy" quantifiers described in PEG papers, but we prefer the term "possessive" to distinguish them from the real "greedy" ones as described below.

### Greedy

A greedy quantifiers backtracks to maximize the match length for the literal chain it belongs to. The following greedy quantifiers are currently limited to be put after literals --- that is --- they can not be put after an expression containing any references.

    'a'+* # one or more 'a', backtracks if consecutive literal pattern not match
          # it backtracks from longest to shortest
    'a'** # zero or more 'a'
    'a'?* # zero or one 'a'

### Reluctant

A reluctant quantifiers tries to repeat as less as they can, also limited to literals.

    'a'+? # one or more 'a', backtracks if consecutive literal pattern not match
          # it backtracks from shortest to longest
    'a'*? # zero or more 'a'
    'a'?? # zero or one 'a'

todo example for greedy / reluctant / possessive.

## Precedent branch

    /

## Block transformers

Every rule allows at most one block transformer wrapped between `{` and `}`.

To access environment in the block

    @env.line
    @env.col
    @env.filename
    TODO: other env information

You have the responsibility to ensure the transformers idempotent --- which means for a certain position in the source code, the processor should return the same result no matter how many times it is called, and the side effects should not accumulate.

If you need a processor that is not idempotent, custom a helper.

By the way, please don't worry about nested braces or strings inside the block, the rule compiler is smart enough to recognize very complex ruby code.

## Helpers

Helpers are tools for building special or complex parsers from basic grammar expressions. Calling a helper looks like invoking a lambda in Ruby. We provide several helpers to help reduce the amount of work.

### Ignore case

The following rule parses either `'a'` or `'A'`:

    i['a']

The only argument of `i[]` must be a literal.

### Joiner

    join[token, joiner]

This rule is equivalent to

    token (joiner token)*

Doesn't look a big improvement huh? But sometimes the first expression can be quite long, repeating it would easily lead to errors, and it's hard to think of the name if you abstract the meaningless partial expression into a new rule. Then `join[]` will help you. For example, you can easily write

    x = join[a / b / c / d / e, ',']

than

    x = a / b / c / d / e (',' (a / b / c / d / e))*

or

    x  = x1 (',' x1)*
    x1 = a / b / c / d / e

### Permutations

Assume you want to parse arbitrary non-recurring permutations of `a`, `b` and `c`, you may write a very complex rule like this:

    a \s+ (b \s+ c / c \s+ b) / b \s+ (a \s+ c / c \s+ a) / c \s+ (a \s+ b / b \s+ a) / a (\s+ (b / c))? / b (\s+ (a / c))? / c (\s+ (a / b))?

These surely will explode if you add one more reference `d`! Or you may give up and use a simpler rule and a block to reject the repeated ones?

    x:(a / b / c)+ { reject if x.uniq != x; x }

Or you can just use the `permutations[]` macro for the dirty job:

    permutations[a, b, c, \s+]

It's very handy for parsing weird syntaces like Java method modifiers `synchronized public static wtf`!

### Indentations

Indentations are hard to fit in PEG syntax, luckily we have helpers for the job:

    indent[]
    dedent[]
    samedent[]

TODO: explain details and other indentation helpers

### Custom helpers

You can customize your helpers too. For example, if you have a `close` helper implemented like this:

```ruby
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
```

You can use it like this:

    expr = x:[\(\[\{\|\<] content close[\k<x>]

Helper generated parsers are not cached by default, so you can apply dynamic non-idempotent logic here if you want. For example, to count how many times the parser is applied:

```ruby
helper[:count] = -> parser {
  parser.map do |res|
    @count ||= 0
    @count += 1
    res
  end
}
```

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

## Modules and dynamic parser modification interface

Change rule AST and re-generate new parsers.

todo

## Transform rules to make all branches inside literals

sell point, good for syntax coloring. todo

## Decent examples

todo

todo add simple examples inside this guide

## Editor support

todo

## A bit background on why we need a grammar syntax

Because:

+ Even the simplest internal DSL is a bit too verbose to show what the grammar does.
+ Internal DSL is hard to make rules declarative.
+ With internal DSL you have to modify symbols to fit host grammar.
+ Grammar definition can be used to generate targets in other languages.

## Left recursion

todo report error at sight of left recursion

todo experiment limited left recursion support

## Dealing with spaces

You know, with PEG you can not use a lexer to just drop out the spaces. My trick is to define `_` as `"\s"*` or `[\t\ ]*`, looks a bit cleaner.

## Dealing with comments

My trick is to embed comment rules inside space rules and end-of-line rules. Example for skipping C++ style comments:

    eol = line_comment | $
    _ = join[\s*, block_comment | eol]
    line_comment = "//" .* $
    block_comment = "/*" [.\n]*? "*/"

## PEG can be sometimes more powerful than CFG

There's already [proof](http://arxiv.org/pdf/1304.3177.pdf) that if we disambiguate LL(k) grammar in a certain way, it can be transformed into a PEG grammar.

But another question is, can PEG express something that's not CFG? Sure! Remember the unlimited look forward!

The example context sensitive language is `L = {a^nb^nc^n | n>0}`. It can not be described with context free grammar, thus not able to be parsed by pure CFG methods. But it can be described with our PEG:

    l = &(x 'c') 'a'+ y
    x = 'a' x* 'b'
    y = 'b' y* 'c'

## PEG and regexp engine, which is more powerful?

It's common misunderstanding that regexp engines are weaker than parser generators, in fact, regexps are weaker but regexp engines are not! A modern regexp engine (except re2, which sacricfices power for speed) has named groups and capable of parsing recursive rules, and there's [research](http://www.inf.puc-rio.br/~roberto/docs/ry10-01.pdf) that found it impossible to convert many constructs like back references into PEG. While PEG rules can be easily converted into Onigmo regexp, as Magan does.

The only weakness of Onigmo is, it's hard to debug into the matching process, fixing this weakness is one goal of Magan.

# License

BSD, see copying

# Thanks

Parslet, Parsley, PEG.js and lots of people working on parser theories.
