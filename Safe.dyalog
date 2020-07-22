:Namespace Safe

    DefaultTimeout←10

    ⎕ML←1 ⋄ ⎕IO←1

    ValidTokens←'⍺⍵¯.⍬{}⊣⌷¨⍨[/⌿\⍀<≤=≥>≠∨∧-+÷×?∊⍴~↑↓⍳○*⌈⌊∇∘(⊂⊃∩∪⊥⊤|;,⍱⍲⍒⍋⍉⌽⊖⍟⌹⍤⌸!⍪≡≢^∣:⍷⋄←⍝)]⊢⊣⍠⊆⍸⌺@'
    ValidTokens,←'⎕RL' '⎕FMT' '⎕CT' '⎕IO' '⎕NC' '⎕NL' '⎕R' '⎕S'
    ValidTokens,←'⎕SIZE' '⎕TS' '⎕UCS' '⎕VFI' '⎕XML' '⎕PP' '⎕D' '⎕A'
    ValidTokens,←'⎕DIV' '⎕JSON' '⎕CR' '⎕NR' '⎕VR' '⎕AT' '⎕DR' '⎕DL' '⎕EM' '⎕FR'
    ValidTokens,←'⍎' '⍣' '⍕' '⌶'⍝ these need special treatment!
    ValidTokens,¨←⊂⍬

    ∇ r←{space_timeout}Exec expr;space;timeout;kid;tid
    ⍝ returns result
    ⍝ if shy, throws 6
    ⍝ if timed out, throws 10
    ⍝ if illegal token, throws 11
    ⍝ if user's code causes error, throws 200+⎕EN
      :If 900⌶⍬ ⍝ monadic?
          space_timeout←⍬
      :EndIf
      space←⊃(space_timeout/⍨326=⎕DR¨space_timeout),⎕NS ⍬ ⍝ default space is new empty
      timeout←⊃(space_timeout/⍨2|⎕DR¨space_timeout),DefaultTimeout ⍝ default timeout
      :If ValidTokens ValidLine expr
          kid←KillAfter&timeout ⍝ Put out a contract on tid
          :Trap 0
              r←⎕TSYNC tid←space AsynchExec&,expr      ⍝ Launch&wait execution in a separate thread
              ⎕TKILL kid ⍝ Kill the assassin
          :Case 6
              ⎕SIGNAL⊂('EN' 10)('EM' 'EXPRESSION TIME LIMIT EXCEEDED')('Message'('Must complete within ',(⍕timeout),' seconds'))('Vendor' '∧')
          :Case 85
              ⎕SIGNAL⊂('EN' 6)('Message' 'Shy or no result')('Vendor'⎕DMX.Vendor)
          :Else
              ⎕SIGNAL⊂⎕DMX.(('EN' 11)('Message'Message)('Vendor'Vendor))
          :EndTrap
      :Else
          ⎕SIGNAL⊂⎕DMX.(('EN' 11)('EM' 'NOT PERMITTED')('Message'Message)('Vendor'Vendor))
      :EndIf
    ∇

      ValidLine←{ ⍝ Parse a single line of code, accepts only tokens in ⍺
          ShR←{¯1↓0,⍵}    ⍝ shift right fn
    ⍝ Split on tokens: names, ⎕names, strings, others
          str←t∨ss←≠\t←⍵=''''     ⍝ where the strings are
          cmnt←∨\str<'⍝'=⍵        ⍝ comment
          ¯1↑ss>cmnt:2 'open quote'    ⍝ detect uneven quotes early
          str←str>cmnt
          ss←str>ShR str          ⍝ where the strings start
          cs←<\cmnt               ⍝ comment start
    ⍝ ⎕names
          quads←(cmnt∨str)<⍵='⎕'         ⍝ where the ⎕s are
          az←'abcdefghijklmnopqrstuvwxyz'
    ⍝ APL user names and numbers, this set is limited; the real set is (0≤⎕nc⍪⎕av)/⎕av
          sn←(ShR quads)<vc>ShR+vc←(cmnt∨str)<⍵∊⎕A,az,'⍺⍵∆⍙_',⎕D
    ⍝ The tokens start where there is no string or name/number:
          t←cs∨sn∨ss∨str⍱vc ⍝ start of name or string or neither a name or a string
          tokens←(t⊂⍵)
    ⍝ Uppercase ⎕fns
          tokens←{'⎕'≠1↑⍵:⍵ ⋄ b←az∊⍨s←⍵ ⋄ (b/s)←⎕A[az⍳b/s] ⋄ s}¨tokens
          ok←(∨\t/cs)∨(t/ss)∨t/sn
          ∧/t←ok∨tokens∊⍺,⊂,' '
      }

      KillAfter←{
    ⍝ Kill (global) tid after some time
          0::
          ⎕TKILL tid⊣⎕DL ⍵ ⍝ Job done!
      }

    ∇ r←space AsynchExec expr;result;dm;offset;t;output;exprs;pre;z;opname;safeExpr;i;Code∆R
    ⍝ Subroutine of Execute - runs in separate thread
    ⍝ Will be killed by "KillAfter" if it takes too long to execute
      space.⎕ML←1
      exprs←splitondiamonds expr
     ⍝ Now we inject covers for ⍣ (so it can be interrupted killed by timeout) and ⍎ and ⍕ and ⌶ (for safety)
      (space.⎕LOCK¨⊢⊣'space'⎕NS⍪)'þéçí'
      Code∆R←{('''[^'']*''' '⍝.*',⊆⍺⍺)⎕R(,¨'&&',⊆⍵⍵)⊢⍵}
     
      :Trap 0
          output←⍬
          ⎕SIGNAL 85↓⍨≢exprs
          :For i :In ⍳⍴exprs
              expr←i⊃exprs
              :If 4=space.⎕NC opname←{(∧\'⍝'≠⍵)/⍵}expr
                  output←⊂{(∨\'{'=⍵)/⍵},space.⎕CR opname
              :Else
                  safeExpr←(,¨'⍣⍎⍕⌶')Code∆R' þ ' ' é ' ' ç ' ' í '⊢expr ⍝ substitute ⍣ and ⍎ and ⍕ wand ⌶ ith covers
                  r←1 space.(85⌶)safeExpr
              :EndIf
          :EndFor
          space.⎕EX⍪'þéçí' ⍝ remove injected covers
      :Else
          space.⎕EX⍪'þéçí' ⍝ remove injected covers
          ⎕SIGNAL⊂⎕DMX.(('EN'(EN+200×⎕EN≠85))('Message'Message)('Vendor'(14↓3⊃DM)))
      :EndTrap
    ∇

      splitondiamonds←{
          b←q⍱∨\('⍝'=⍵)>q←≠\''''=⍵         ⍝ Not in quotes or comment
          b←b∧0=+\b×(1 ¯1 0)['{}'⍳⍵]       ⍝ Not in a dfn body
          (b⍲'⋄'=⍵)⊆⍵}

    :Section Covers
    ∇ r←{a}(aa þ ww)w ⍝ cover for ⍣ (allows interruption)
      :If 900⌶⍬ ⋄ a←⊢ ⋄ :EndIf
      r←a(aa{⍺←⊢ ⋄ ⍺ ⍺⍺ ⍵}⍣ww)w
    ∇
    ∇ r←{a}é w;v;f ⍝ cover for ⍎ (allows only numbers)
      ⎕SIGNAL(0∊⊃v f←⎕VFI w)/⊂('EN' 11)('Message' '⍎ is limited to only the conversion of text to numbers')
      r←⊃⍣(1=≢f)⊢f
    ∇
    ∇ r←{a}ç w ⍝ cover for ⍕ (disallows inverse)
      :If 900⌶⍬ ⋄ a←⊢ ⋄ :EndIf
      r←a⍕w
    ∇
    ∇ r←{a}(aa í)w ⍝ cover for ⌶ (allows only case conversion)
      ⎕SIGNAL((,819)≢,aa)/⊂('EN' 11)('Message' '⌶ is limited to only case convertion of text (819⌶)')
      :If 900⌶⍬ ⋄ a←⊢ ⋄ :EndIf
      r←a(819⌶)w
    ∇
    :EndSection

:EndNamespace
