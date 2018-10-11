 Example;ns;expr;res
 ns←⎕NS ⍬
 :Repeat
     ⎕←'Enter an expression (→ to leave):'
     ⍞←6⍴''
     expr←⍞
     :Select expr~' '
     :Case ,'→'
         :Leave
     :Case ''
         ⎕←'Not an expression'
     :Else
         :Trap 0
             res←1 ns Safe.Exec expr
         :Case 6 ⍝ shy or no result: ignore
             :Continue
         :Case 10
             ⎕←'** That took too long'
             :Continue
         :Case 11
             ⎕←'** That is not allowed'
             :Continue
         :Else
             ⎕←'** Your expression caused a ',⎕EM ⎕EN-200
             :Continue
         :EndTrap
         ⎕←'Result is:'
         ⎕←res
     :EndSelect
 :EndRepeat
