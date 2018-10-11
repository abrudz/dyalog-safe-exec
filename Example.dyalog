 Example;ns;expr;res
 ns←⎕NS ⍬ ⍝ initialise namespace
 :Repeat
     ⎕←'Enter an expression (→ to leave):'
     ⍞←6⍴'' ⍝ six-space prompt
     expr←⍞
     :Select expr~' '
     :Case ,'→' ⍝ user wants to leave
         :Leave
     :Case ''  ⍝ all empty
         ⎕←'Not an expression'
     :Else
         :Trap 0
             res←1 ns Safe.Exec expr ⍝ 1 second time limit
         :Case 6 ⍝ shy or no result: ignore
             :Continue
         :Case 10 ⍝ timeout
             ⎕←'** That took too long'
             :Continue
         :Case 11 ⍝ illegal
             ⎕←'** That is not allowed'
             :Continue
         :Else ⍝ user error
             ⎕←'** Your expression caused a ',⎕EM ⎕EN-200
             :Continue
         :EndTrap
         ⎕←'Result is:' ⍝ everything ok
         ⎕←res
     :EndSelect
 :EndRepeat
