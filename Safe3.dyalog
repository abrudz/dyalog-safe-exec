:Namespace Safe3
    DefaultTimeout←10
    ⎕ML←1 ⋄ ⎕IO←1

    ∇ defs←coverdefs
      defs←↓⍉[
          'sûre_NL' '⎕NL'
          'sûre_FX' '⎕FX'
          'sûre_power' '⍣'
          'sûre_execute' '⍎'
          'sûre_format' '⍕'
          'sûre_ibeam' '⌶'
          'sûre_NS' '⎕NS'
          'sûre_VGET' '⎕VGET'
          'sûre_VSET' '⎕VSET'
      ]
    ∇
    (covers covered)←coverdefs
    ValidTokens←covered
    ValidTokens,←'⍺⍵¯.⍬{}⊣⌷¨⍨[/⌿\⍀<≤=≥>≠∨∧-+÷×?∊⍴~↑↓⍳○*⌈⌊∇∘(⊂⊃∩∪⊥⊤|;,⍱⍲⍒⍋⍉⌽⊖⍟⌹⍤⍥⌸!⍪≡≢^∣:⍷⋄←⍝)]⊢⊣⍠⊆⍸⌺@⍛'
    ValidTokens,←'⎕RL' '⎕FMT' '⎕CT' '⎕IO' '⎕NC' '⎕R' '⎕S'  '⎕C' '⎕DT' '⎕AV'
    ValidTokens,←'⎕SIZE' '⎕TS' '⎕UCS' '⎕VFI' '⎕XML' '⎕PP' '⎕D' '⎕A' '⎕AVU'
    ValidTokens,←'⎕DIV' '⎕JSON' '⎕CR' '⎕NR' '⎕VR' '⎕AT' '⎕ATX' '⎕DR' '⎕DL' '⎕FR' '⎕WG' '⎕DCT' '⎕THIS'
    ValidTokens,¨←⊂⍬
    Code∆R←{('''[^'']*''' '⍝.*',⊆⍺⍺)⎕R(,¨'&&',⊆⍵⍵)⍠1⊢⍵}
    covered←'\w$'⎕R'&\\b'⊢covered
    CoverUp←covered Code∆R(' ',¨covers,¨' ')
    debug←0
    monitor←0
    tasks←⍬ ⍬
    ∇ r←{space_timeout}Exec expr;ExCovers;dmx;space;tid;timeout;shy;thread;ok;badTokens;msg;badToken
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
      shy←0=≢'^\s*⎕\s*←'⎕S 3⊢expr
      expr←'^\s*⎕\s*←'Code∆R''⊢expr
      (ok badTokens)←ValidTokens ReportLine⍕↓⎕FMT expr
      :If ok
          :If 0=monitor
              tasks←⍬ ⍬
              monitor←Monitor&1
          :EndIf
          :Trap debug↓0 0
              ExCovers←{⍵.⎕EX covers,'ß'}
              :Hold 'tasks'
                  tasks{⍺,¨debug↓¨⍵}←(thread←space ÁsynchExec&,expr)(timeout+20 ⎕DT'Z')      ⍝ Launch&wait execution in a separate thread
              :EndHold
              ⎕TSYNC thread
              ExCovers space  ⍝ remove injected covers
              :If 3 4∊⍨⎕NC'space.résult'
                  r←space.(⎕EX⊢⎕OR)'résult'
              :Else
                  r←space.(⎕EX⊢⎕VGET)'résult'
              :EndIf
          :Case 6
              ExCovers space  ⍝ remove injected covers
              ⎕SIGNAL⊂('EN' 10)('EM' 'EXPRESSION TIME LIMIT EXCEEDED')('Message'('Must complete within ',(⍕timeout),' seconds'))('Vendor' '∧')
          :Case 85
              ExCovers space  ⍝ remove injected covers
              ⎕SIGNAL⊂('EN' 6)('Message' 'Shy or no result')('Vendor'⎕DMX.Vendor)
          :Else
              dmx←⎕DMX
              ExCovers space  ⍝ remove injected covers
              ⎕SIGNAL⊂dmx.(('EN'EN)('Message'Message)('Vendor'Vendor))
          :EndTrap
      :Else
          msg←''
          :If ×≢badTokens
              :For badToken :In ∪badTokens
                  :If 1=≢badToken
                      msg,←(1 ⎕JSON ⎕OPT('Charset' 'ASCII')('Dialect' 'JSON5')⊢badToken),' (⎕UCS ',(⍕⎕UCS badToken),')'
                  :Else
                      msg,←badToken
                  :EndIf
                  msg,←', '
              :EndFor
              msg↓⍨←¯2
          :EndIf
          ⎕SIGNAL⊂('EN' 11)('EM' 'NOT SUPPORTED')('Message'msg)
      :EndIf
    ∇
    ∇ Monitor go;stop;now;expired;cr
      cr←⎕UCS 13
      :If go
          :Repeat
              :Trap 0
                  :Repeat
                      :Hold 'tasks'
                          now←20 ⎕DT'Z'
                          stop←now>⊃⌽tasks
                          expired←stop/⊃tasks
                          tasks/¨⍨←⊂~stop
                      :EndHold
                      ⎕TKILL expired
                      ⎕DL 1
                  :EndRepeat
              :EndTrap
              :Hold 'tasks'
                  :Trap 1
                      ⍞←'Monitor failed ─ killed all task threads!'
                      ⍞←cr,'Workspace available before and after compaction: ',⍕2000⌶0
                      ⍞←'→',⍕⎕WA
                      ⍞←cr,'Tasks: ',≢⊃tasks
                  :EndTrap
                  ⎕TKILL⊃tasks
                  tasks←⍬ ⍬
                  ⍞←cr,'⎕DMX: ',⎕JSON ⎕DMX
              :EndHold
          :EndRepeat
      :Else
          ⎕TKILL monitor,⊃tasks
      :EndIf
    ∇
      ReportLine←{ ⍝ Parse a single line of code, accepts only tokens in ⍺
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
          oks←(∨\t/cs)∨(t/ss)∨t/sn
          ok←∧/t←oks∨tokens∊⍺,⊂,' '
          ok((tokens/⍨~oks)~⍺,⊂,' ')
      }
    ValidLine←⊃ReportLine

    ∇ space ÁsynchExec expr;result;dm;offset;t;exprs;pre;z;opname;safeExpr;i;lf;dmx;vendor;en
    ⍝ Subroutine of Exec - runs in separate thread
    ⍝ Will be killed by "Monitor" if it takes too long to execute
      space.⎕ML←1
      exprs←splitondiamonds expr
     ⍝ Now we inject covers for ⍣ (so it can be interrupted killed by timeout) and ⍎ and ⍕ and ⌶ (for safety)
      :If 2=debug
          (1+⊃⎕LC)⎕STOP⊃⎕SI
      :EndIf
      'space'⎕NS covers
      :If 0=debug
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
                  safeExpr←'^\s+'⎕R''⍠'Mode' 'D'CoverUp expr ⍝ substitute covers for what they cover
                  :If 2≤≢⎕FMT safeExpr
                      :If '∇'=⊃safeExpr
                          :If ≡space.⎕FX ⎕FMT safeExpr
                              ⎕SIGNAL 85
                          :Else
                              space.résult←'defn error'
                          :EndIf
                      :ElseIf ≢'^\s*[\w∆⍙]+\s*←'⎕S 3⍠'Mode' 'D'⊢safeExpr
                          safeExpr,⍨←'__sessionínput__',lf,'⎕EX⍬⍴⎕SI',lf←⎕UCS 10
                          space.⎕FX ⎕FMT safeExpr
                          space.__sessionínput__
                          ⎕SIGNAL 85
                      :Else
                          safeExpr←'''[^'']+''' '(⍝.*)?\n'⎕R'&' ' ⋄ '⍠'Mode' 'D'⊢safeExpr
                          space.résult←shy space.(85⌶)safeExpr
                      :EndIf
                  :Else
                      space.résult←shy space.(85⌶)safeExpr
                  :EndIf
              :EndIf
          :EndFor
      :Else
          dmx←⎕JSON ⎕JSON ⎕DMX
          ⍝ Hide SafeExec artifacts from predictable error messages. Some error message might display incorrectly.
          vendor←1 ⎕JSON dmx.DM↓¨⍨1 14 14×∧/(,'⍎')'ÁsynchExec[41]'(14⍴'')≡¨1 14 14↑¨dmx.DM
          en←dmx.((200|EN)+200×EN≠85)
          ⎕SIGNAL⊂('EN'en)('Message'dmx.Message)('Vendor'vendor)
      :EndTrap
    ∇
      splitondiamonds←{
          ⎕IO←0
          b←q⍱∨\('⍝'=⍵)>q←≠\''''=⍵           ⍝ Not in quotes or comment
          b←b∧0=+\b×(1 ¯1 0)[3|'{}}[]]()'⍳⍵] ⍝ Not in bracketed
          (b⍲'⋄'=⍵)⊆⍵}
    :Section Covers

    ∇ ø←{á}(áá sûre_power óó)ó ⍝ cover for ⍣ (allows interruption)
      :If 900⌶⍬ ⋄ á←⊢ ⋄ :EndIf
      :If 2=⎕NC'óó'
          áá←áá⍣(×óó)
      :EndIf
      ø←á(áá{⍺←⊢ ⋄ ⍺ ⍺⍺ ⍵}⍣(|óó))ó
    ∇
    ∇ ø←{á}sûre_execute ó;ók;mésg;badTókens;bádToken ⍝ cover for ⍎ (allows only numbers)
      ⎕SIGNAL 11↓⍨(1≥≢⍴ó)∧(80 160 320∊⍨⎕DR ó) ⍝ hi-rank or char
      (ók badTókens)←ß.(ValidTokens∘ReportLine)ó←,ó
      :If ók
          :Trap 85
              ⎕THIS ß.ÁsynchExec ó
          :EndTrap
          :If ×⎕NC'résult'
              ø←résult
          :EndIf
          ⎕EX'résult'
      :Else
          mésg←''
          :If ×≢badTókens
              :For bádToken :In ∪badTókens
                  :If 1=≢bádToken
                      mésg,←(1 ⎕JSON ⎕OPT('Charset' 'ASCII')('Dialect' 'JSON5')⊢bádToken),' (⎕UCS ',(⍕⎕UCS bádToken),')'
                  :Else
                      mésg,←bádToken
                  :EndIf
                  mésg,←', '
              :EndFor
              mésg↓⍨←¯2
          :EndIf
          ⎕SIGNAL⊂('EN' 11)('EM' 'NOT SUPPORTED')('Message'mésg)
      :EndIf
    ∇
    ∇ ø←{á}sûre_format ó ⍝ cover for ⍕ (disallows inverse)
      :If 900⌶⍬ ⋄ á←⊢ ⋄ :EndIf
      ø←á⍕ó
    ∇
    ∇ ø←{á}(áá sûre_ibeam)ó ⍝ cover for ⌶ (allows only date-time formatting)
      ⎕SIGNAL(~(⊂,áá)∊,¨,120 1200 5581)/⊂('EN' 11)('EM' 'NOT PERMITTED')('Message' '⌶ is limited to Generate UUID (120⌶), Format Date-time (1200⌶), and Unicode Normalisation (5581⌶)')
      :If 900⌶⍬ ⋄ á←⊢ ⋄ :EndIf
      ø←á(áá⌶)ó
    ∇
    ∇ ø←{á}sûre_NL ó  ⍝ cover for ⎕NL (hides covers)
      :If 900⌶⍬ ⋄ á←⊢ ⋄ :EndIf
      ø←á ⎕NL ó
      ø⌿⍨←'û'≠ø[;2]
    ∇
    ∇ {náme}←{á}sûre_FX ó;náme;mésg;badTókens;bádToken;ók  ⍝ cover for ⎕FX (refuses unsafe code)
      (ók badTókens)←ß.(ValidTokens∘ReportLine),' '↑ó
      :If ók
          ó←ß.CoverUp ó
          náme←⎕FX ó
          :If ⍬≡0/náme
              ⎕SIGNAL⊂('EN' 11)('EM' 'DEFN ERROR')('Message'('Problem on line',⍕náme))
          :ElseIf ~3.1 3.2 4.1 4.2∊⍨⎕NC⊂náme
              ⎕EX náme
              ⎕SIGNAL⊂('EN' 11)('EM' 'NOT SUPPORTED')('Message' 'Must be tradfn/tradop/dfn/dop')
          :EndIf
      :Else
          mésg←''
          :If ×≢badTókens
              :For bádToken :In ∪badTókens
                  :If 1=≢bádToken
                      mésg,←(1 ⎕JSON ⎕OPT('Charset' 'ASCII')('Dialect' 'JSON5')⊢bádToken),' (⎕UCS ',(⍕⎕UCS bádToken),')'
                  :Else
                      mésg,←bádToken
                  :EndIf
                  mésg,←', '
              :EndFor
              mésg↓⍨←¯2
          :EndIf
          ⎕SIGNAL⊂('EN' 11)('EM' 'NOT SUPPORTED')('Message'mésg)
      :EndIf
    ∇
    ∇ ø←{á}sûre_NS ó ⍝ cover for ⎕NS (disallows going up the ns structure)
      :If 900⌶⍬ ⋄ á←⊢ ⋄ :EndIf
      ⎕SIGNAL(∨/'#⎕'∊∊á ó)⍴⊂('EN' 11)('EM' 'NOT SUPPORTED')('Message' 'Install Dyalog to access namespaces up the hierarchy')
      ø←á ⎕NS ó
    ∇
    ∇ ø←{á}sûre_VGET ó ⍝ cover for ⎕VGET (disallows going up the ns structure)
      :If 900⌶⍬ ⋄ á←⊢ ⋄ :EndIf
      ⎕SIGNAL(∨/'#⎕'∊∊á ó)⍴⊂('EN' 11)('EM' 'NOT SUPPORTED')('Message' 'Install Dyalog to access namespaces up the hierarchy')
      ø←á ⎕VGET ó
    ∇
    ∇ {ø}←{á}sûre_VSET ó ⍝ cover for ⎕VSET (disallows going up the ns structure)
      :If 900⌶⍬ ⋄ á←⊢ ⋄ :EndIf
      ⎕SIGNAL(∨/'#⎕'∊∊á ó)⍴⊂('EN' 11)('EM' 'NOT SUPPORTED')('Message' 'Install Dyalog to access namespaces up the hierarchy')
      ø←á ⎕VSET ó
    ∇
    :EndSection
:EndNamespace
