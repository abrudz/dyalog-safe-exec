![Safe Execute Logo](logo.svg)
# Safe Execute for [Dyalog APL](https://www.dyalog.com/)
*Drop-in for* `⍎` *to execute arbitrary APL code safely*

Load with  `⎕FIX 'file://path/Safe.dyalog'` then execute an expression with for example `Safe.Exec '⍳10'`.

Expressions are executed in a new empty namespace with `⎕IO←1` and `⎕ML←1`, but you can also supply a namespace ref in the optional left argument, and the expression will then be executed there.

The left argument may also contain a number indicating a timeout for expressions. If no such number is given, `10` (seconds) will be used.

If an error occcurs in the expression, it will be re-signalled from `Safe.Exec` but with error number incremented by `200`. E.g. a `DOMAIN ERROR` which is normally error number (`⎕EN`) `11` will be signalled as `211`.

The following errors may also be signalled:

`6` (`VALUE ERROR`) if the expression is shy or has no result

`10` (`EXPRESSION TIME LIMIT EXCEEDED`) if the expression timed out

`11` (`NOT PERMITTED`) if the expression attempted to use a restricted feature.

## Example usage

```
      ns←⎕NS ⍬
      ns.A←10
      ns Safe.Exec '⍳A'
1 2 3 4 5 6 7 8 9 10
```

For a more advanced example preserving a state and handling errors, see `Example.dyalog`.

## Logo

By [dzaima](https://chat.stackexchange.com/transcript/message/56823573#56823573) and [Wezl](https://chat.stackexchange.com/transcript/message/56823580#56823580).
