# turing-machine
Turing machine written in C/Racket and examples

# compile
We can use GCC or another compiler to compile the simulator
```
gcc -O2 turing.c -o turing
```
And, we can use racket, too.
```
raco exe -o turing turing.rkt
```

# Description
In this simulator, we indicate states in number.  
| state | descrition |  
| :---  | :--------- |  
| 0 | initial state |  
| 1 | accept state |  
| 2 | reject state |  
1/2 means that the turing machine stops to work.  
And, we can use other states.  
We indicate letters in number, too.  
| letter | description |  
| :---  | :--------- |  
|0      | BLANK      |  
And, we can use other letters.

Tuing machines include some rules.  
Each rule is as following:  
| :---: |  :---: |  :---: |  :---: |  :---: |
| current-state | current-letter | next-state | next-letter | head-direction |

head-direction:  
|direction|description|
| :-- | :-- |  
|0/R  | move head to the right |  
|1/L  | move head to the left |  

And, we can use '-' in the next-state/next-letter fields that means the state/letter doesn't change.
And, we can use '-' in the current-letter field that means this rule sutes for all the letters except BLANK.
And, we can use '*' in the current-letter field that means this rule sutes for all the letters including BLANK.

# Language
The laguage accepted by turing machines is inputed by the standard input.
```
echo 1 2 3 4 5 6 | ./turing test.rule
```
It means that the tape is as following:
```
1 2 3 4 5 6 BLANK BLANK BLANK ...
```
And the turing machine description file is 'test.rule'.
