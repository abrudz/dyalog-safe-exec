:Namespace Safe
    DefaultTimeout←10
    ⎕ML←1 ⋄ ⎕IO←1
    ValidTokens←'⍺⍵¯.⍬{}⊣⌷¨⍨[/⌿\⍀<≤=≥>≠∨∧-+÷×?∊⍴~↑↓⍳○*⌈⌊∇∘(⊂⊃∩∪⊥⊤|;,⍱⍲⍒⍋⍉⌽⊖⍟⌹⍤⍥⌸!⍪≡≢^∣:⍷⋄←⍝)]⊢⊣⍠⊆⍸⌺@'
    ValidTokens,←'⎕RL' '⎕FMT' '⎕CT' '⎕IO' '⎕NC' '⎕NL' '⎕R' '⎕S'  '⎕C' '⎕DT'
    ValidTokens,←'⎕SIZE' '⎕TS' '⎕UCS' '⎕VFI' '⎕XML' '⎕PP' '⎕D' '⎕A' '⎕AVU'
    ValidTokens,←'⎕DIV' '⎕JSON' '⎕CR' '⎕NR' '⎕VR' '⎕AT' '⎕DR' '⎕DL' '⎕FR'
    ValidTokens,←'⍎' '⍣' '⍕' '⌶' '⎕FX' ⍝ these need special treatment!
    ValidTokens,¨←⊂⍬
    Code∆R←{('''[^'']*''' '⍝.*',⊆⍺⍺)⎕R(,¨'&&',⊆⍵⍵)⊢⍵}
    covered←'⎕NL\b' '⎕FX\b' '⍣' '⍎' '⍕' '⌶'
    covers←'ÑÍþéçí'
    CoverUp←covered Code∆R(' ',¨covers,¨' ')
    debug←0
    ∇ r←{space_timeout}Exec expr;space;timeout;kid;tid;dmx;ExCovers
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
      expr←'^\s*⎕\s*←'Code∆R'⊢'⊢expr
      :If ValidTokens ValidLine expr
          kid←KillAfter&timeout ⍝ Put out a contract on tid
          :Trap debug↓0
              ExCovers←{⍵.⎕EX⍪covers,'ß'}
              ⎕TSYNC tid←space AsynchExec&,expr      ⍝ Launch&wait execution in a separate thread
              ⎕TKILL kid ⍝ Kill the assassin
              ExCovers space  ⍝ remove injected covers
              r←space.(⎕EX⊢⎕OR)'résult'
          :Case 6
              ⎕TKILL kid ⍝ Kill the assassin
              ExCovers space  ⍝ remove injected covers
              ⎕SIGNAL⊂('EN' 10)('EM' 'EXPRESSION TIME LIMIT EXCEEDED')('Message'('Must complete within ',(⍕timeout),' seconds'))('Vendor' '∧')
          :Case 85
              ⎕TKILL kid ⍝ Kill the assassin
              ExCovers space  ⍝ remove injected covers
              ⎕SIGNAL⊂('EN' 6)('Message' 'Shy or no result')('Vendor'⎕DMX.Vendor)
          :Else
              dmx←⎕DMX
              ⎕TKILL kid ⍝ Kill the assassin
              ExCovers space  ⍝ remove injected covers
              ⎕SIGNAL⊂dmx.(('EN'EN)('Message'Message)('Vendor'Vendor))
          :EndTrap
      :Else
          ⎕SIGNAL⊂⎕DMX.(('EN' 11)('EM' 'NOT PERMITTED')('Message' 'Illegal token'))
      :EndIf
    ∇
      ValidLine←{ ⍝ Parse a single line of code, accepts only tokens in ⍺
          ShR←{¯1↓0,⍵}    ⍝ shift right fn
    ⍝ Split on tokens: names, ⎕names, strings, others
          str←t∨ss←≠\t←⍵=''''     ⍝ where the strings are
          cmnt←∨\str<'⍝'=⍵        ⍝ comment
          ¯1↑ss>cmnt:⎕SIGNAL⊂('EN' 2)('Message' 'Unpaired quote') ⍝ detect uneven quotes early
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
          0=⍵:
          ⎕TKILL tid⊣⎕DL ⍵ ⍝ Job done!
      }
    ∇ space AsynchExec expr;result;dm;offset;t;exprs;pre;z;opname;safeExpr;i
    ⍝ Subroutine of Execute - runs in separate thread
    ⍝ Will be killed by "KillAfter" if it takes too long to execute
      space.⎕ML←1
      exprs←splitondiamonds expr
     ⍝ Now we inject covers for ⍣ (so it can be interrupted killed by timeout) and ⍎ and ⍕ and ⌶ (for safety)
      'space'⎕NS⍪covers
      :If ~debug
          space.⎕LOCK¨covers
      :EndIf
      space.ß←⎕THIS
     
      :Trap debug↓0
          output←⍬
          ⎕SIGNAL 85/⍨0=≢exprs
          :For i :In ⍳⍴exprs
              expr←i⊃exprs
              space.⎕EX'résult'
              :If 4=space.⎕NC opname←{(∧\'⍝'≠⍵)/⍵}expr
                  space⍎'résult←',opname
              :Else
                  safeExpr←CoverUp expr ⍝ substitute covers for what they cover
                  space.résult←1 space.(85⌶)safeExpr
              :EndIf
          :EndFor
      :Else
          ⎕SIGNAL⊂⎕DMX.(('EN'((200|EN)+200×⎕EN≠85))('Message'Message)('Vendor'(14↓3⊃⎕DM))) ⍝ Why doesn't 3⊃DM work?
      :EndTrap
    ∇
      splitondiamonds←{
          b←q⍱∨\('⍝'=⍵)>q←≠\''''=⍵         ⍝ Not in quotes or comment
          b←b∧0=+\b×(1 ¯1 0)['{}'⍳⍵]       ⍝ Not in a dfn body
          (b⍲'⋄'=⍵)⊆⍵}
    :Section Covers
    ∇ ø←{á}(áá þ óó)ó ⍝ cover for ⍣ (allows interruption)
      :If 900⌶⍬ ⋄ á←⊢ ⋄ :EndIf
      :If 2=⎕NC'óó'
          áá←áá⍣(×óó)
      :EndIf
      ø←á(áá{⍺←⊢ ⋄ ⍺ ⍺⍺ ⍵}⍣(|óó))ó
    ∇
    ∇ ø←{á}é ó ⍝ cover for ⍎ (allows only numbers)
      :If 1≥≢⍴ó
      :AndIf 80 160 320∊⍨⎕DR ó ⍝ char
      :AndIf ß.(ValidTokens∘ValidLine)ó←,ó
          :Trap 85
              ⎕THIS ß.AsynchExec ó
          :EndTrap
          :If ×⎕NC'résult'
              ø←résult
          :EndIf
          ⎕EX'résult'
      :Else
          ⎕SIGNAL⊂⎕DMX.(('EN' 11)('EM' 'NOT PERMITTED')('Message' 'Illegal token'))
      :EndIf
    ∇
    ∇ ø←{á}ç ó ⍝ cover for ⍕ (disallows inverse)
      :If 900⌶⍬ ⋄ á←⊢ ⋄ :EndIf
      ø←á⍕ó
    ∇
    ∇ ø←{á}(áá í)ó ⍝ cover for ⌶ (allows only case conversion and date formatting)
      ⎕SIGNAL(~(⊂,áá)∊,¨819 1200)/⊂('EN' 11)('Message' '⌶ is limited to case conversion (819⌶) and date formatting (1200⌶)')
      :If 900⌶⍬ ⋄ á←⊢ ⋄ :EndIf
      ø←á(áá⌶)ó
    ∇
    ∇ ø←{á}Ñ ó  ⍝ cover for ⎕NL (hides covers)
      :If 900⌶⍬ ⋄ á←⊢ ⋄ :EndIf
      ø←á ⎕NL ó
      ø⌿⍨←(⊃⍤1↑ø)∊⎕A,'⍺⍵∆⍙_',⎕C ⎕A
    ∇
    ∇ {náme}←{á}Í ó;náme  ⍝ cover for ⎕FX (refuses unsafe code)
      :If ∧/,ß.(ValidTokens∘ValidLine)⍤1↑ó
          ó←ß.CoverUp ó
          náme←⎕FX ó
          :If ⍬≡0/náme
              ⎕SIGNAL⊂('EN' 11)('EM' 'DEFN ERROR')
          :ElseIf ~3.1 3.2 4.1 4.2∊⍨⎕NC⊂náme
              ⎕EX náme
              ⎕SIGNAL⊂('EN' 11)('Message' 'Install Dyalog to allow this')
          :EndIf
      :Else
          ⎕SIGNAL⊂('EN' 11)('Message' 'Install Dyalog to allow this')
      :EndIf
    ∇
    :EndSection
:EndNamespace
