---
# try also 'default' to start simple
fonts:
  sans: 'Comfortaa'
  serif: 'Roboto Slab'
  mono: 'JetBrains Mono'

theme: academic 

download: true

# apply any windi css classes to the current slide
class: 'text-center'
# https://sli.dev/custom/highlighters.html
highlighter: shiki
# show line numbers in code blocks
lineNumbers: true
# persist drawings in exports and build
drawings:
  persist: false
# css: unocss
---

## Identifying Hierarchical Structure in Sequences: <br> A linear time algorithm

*Craig G. Nevill-Manning · Ian H. Witten*

---

# structure

<v-clicks>

0. structure
1. motivation
3. algorithm
    1. concept
    2. implementation
    3. complexity
4. evaluation
    1. showcase
    2. comparison to other compression algorithms
    3. summary

</v-clicks>

--- 
layout: center
---

# motivation 

> what goal does `sequitur` pursue?

<v-clicks>

- infer structure from a *stream* of symbols
- use this structure to compress the stream in a continuous/incremental manner
- do it *fast* and *lossless* 

</v-clicks>

--- 
layout: figure
figureCaption: inferred structure for the same sentences in the (a) English, (b) French 
  and (c) German bible
figureUrl: inferred-structures-bible.png
---

# motivation - bible

<!-- 
- we will use two rules to infer a context free grammar
- on the picture: 
  - **remark**: the whole thing was run on the whole corpus not 
    just on this sentence (similarity to training in ML; could 
    be seen as a form of unsupervised learning)
  - inference of word boundaries (in German example complete)
  - **beginning**: separated into: begin - ning
  - **commencement**: separated into: commence - ment
  - *this is a complete possible parsing of the sentence*
-->

--- 
layout: figure
figureCaption: inferred structure for (d) a sentence in the oslo-bergen corpus (e) chorales
  by J.S. Bach
figureUrl: inferred-structures-oslo-bergen-and-bach.png
---

# motivation - corpus, chorales

<!-- 
- on the picture: 
  - corpus
    - *"sentiment would still favour the abolition"* as distinct block
    - *"of the house of Lord"* as adjectival phrase
  - chorale
    - light grey boxes indicated repetition
    - repeated motifs
    - identifies the imperfect/perfect cadences
-->


--- 
layout: center
---

# algorithm

> the `sequitur` algorithm

--- 

## algorithm - concept: digram uniqueness

> each digram appears at most once in the grammar


<v-click>

*observed:* `abcdbc` (`a[bc]d[bc]`)

```haskell {1|3-4}
S -> abcdbc  -- `bc` appears twice

S -> aAdA    -- ensure digram uniqueness
A -> bc
```

</v-click>

<v-click>

*observed:* `abcdbcabcdbcbc` (`[[a[bc]][d[bc]][[a[bc]][d[bc]]][bc]`)

```haskell {1-3|5-7}
S -> AAbc    -- `bc` appers in `S` and `B`
A -> aBdB
B -> bc

S -> AAB     -- ensure digram uniqueness
A -> aBdB
B -> bc
```

</v-click>

---

## algorithm - concept: rule utility

> if a rule is only used once, we resubstitute to save space and 
  extend the length of the rule

<v-click>

*observed:* `abcabc` (`[abc][abc]`)

```haskell {1-2|4-6|8-9}
S -> AcAc    -- `Ac` appears twice
A -> ab

S -> BB     -- digram uniqueness
A -> ab     -- `A` only appears once
B -> Ac     -- namely here 

S -> BB 
B -> abc    -- resubstitute 
```

</v-click>

<v-click>

*observed:* `abcdbcabcd` (`[a[bc]d][bc][a[bc]d]`)

```haskell {1-4|6-8}
S -> CAC
A -> bc
B -> aA      -- `B` is used only once
C -> Bd      -- namely here

S -> CAC
A -> bc
C -> aAd     -- resubstitute `aA` for `B`
```

</v-click>

--- 

## algorithm - full example

*observed:* `abcdbcabc` (`[a[bc]]d[bc][a[bc]]`)

<v-click>

```haskell 
S -> BdAB
A -> bc
B -> aA
```

</v-click>

<v-click>

observe `d`
</v-click>

<v-click>

*observed:* `abcdbcabcd` (`[a[bc]d][bc][a[bc]d]`)

```haskell {1-3|5-8|10-12}
S -> BdABd   -- append `d`, `Bd` appears twice
A -> bc
B -> aA

A -> CAC     -- digram uniqueness
A -> bc
B -> aA      -- `B` only appears once
C -> Bd      

S -> CAC
A -> bc
C -> aAd     -- rule utility
```

</v-click>

<!-- 
- note: same example as before
- this time with all the rules
-->

---
layout: center
---

# implementation

> running `sequitur` on a machine

---

## implementation - constraints

<v-clicks>

- *append* to `S`
  - we need fast `snoc`
- *use* a rule 
  - substitute a non-terminal by any digram (this *shortens* the rule)
- *create* a rule
  - non-terminal on LHS
  - digram on RHS
- *delete* a rule
  - move RHS to replace a non-terminal
  - delete LHS

</v-clicks>

---

## implementation - datastructures

<v-click>

### grammar and digramindex

```
 grammar (linked list)     │ digramindex (hashtable)
           ┌───────────────┼────────┐
           │               │        │
      ┌────┼─────────┐     │        │
      │    │         │     │        │
┌─┐   ▼   ┌▼┐  ┌─┐  ┌┴┐    │ ┌────┐ │
│A├─►┌┬┬─►│B├─►│c├─►│d│  ┌─┼─┤{cd}│ │
└─┘  └─┘  └┬┘  └▲┘  └─┘  │ │ ├────┤ │
           │    │        │ │ │{Bc}├─┘
 ┌─────────┘    └────────┘ │ ├────┤
 │                         │ │{ab}│
 │    ┌─────────┐          │ └──┬─┘
 │    │         │          │    │
┌▼┐   ▼   ┌─┐  ┌┴┐         │    │
│B├─►┌┬┬─►│a├─►│b│         │    │
└─┘  └─┘  └▲┘  └─┘         │    │
           │               │    │
           └───────────────┼────┘
                           │
```

</v-click>

<!-- 
- observe a new digram 
- look it up in the digram index 
- if it exists follow to the link
- talk about digram reference counter? 
-->


--- 

## implementation - example

*observed:* `abcdbc` (`a[bc]d[bc]`)

```haskell {1|3-4|6-7|9-10}
S -> abcdbc  { ab, bc, cd, db } 

S -> abcdbc  { ab, bc, cd, db }  -- create rule that produces `bc`
A -> bc 

S -> aAdbc   { bc, db, aA, Ad }  -- update `ab`, `cd`;  update `S` rule
A -> bc

S -> aAdA    { bc, dA, aC, Ad }  -- update `db`; update `S` rule
A -> bc
```
--- 

## implementation - complexity


```text {all|1|3-10|12-14|all}
upon observation append symbol to `S` - Rule                   (1)

entry in grammar rule is made:                                 (2)
  if digram is repetition then 
    if other occurence is rule then
      replace digram by non-terminal of that rule              (3)
    else
      form new rule                                            (4)
  else
    insert digram into index

digram replaced by a non-terminal:
  if either symbol is non-terminal that only occurs once then 
    remove rule substituting its LHS for observed non-terminal (5)
```
<v-clicks>

- `(1)` performed exactly $n$ times 
- `(2)` performed upon link creation
- `(3)`,`(4)`,`(5)` with savings $1$, $0$, $1$ respectively

</v-clicks>

<!-- 
- amortized (not per symbol but per sequence) 
- per symbol it might be as bad as **O(sqrt n)** for **n** preceding input symbols

- 1 append to srule 
- 3-10 digram uniqueness
- 12-14 rule utility

- 3 using a rule
- 4 adding a rule
- 5 removing a rule
-->

--- 

## implementation - complexity

<v-click>

- $n$ - size of input
- $o$ - size of final grammar
- $r$ - number of rules in final grammar

</v-click>

<v-clicks>

- $a_1 - a_5$ actions `(1)`-`(5)` respectively
- $n-o = a_3 - a_5$
- $r = a_4 - a_5$
- $r < o \equiv r - o < 0$ 
- $a_5 = n-o-a_3 \lt n$

</v-clicks>

<v-click>

$$\sum_{i = 1}^5 a_i = 2n + (r-o) + a_5 + a_2 \lt 3n+a_2$$

</v-click>

 <!-- 
 - the size reduction of the grammar is equal to the amount of times that 3 and 5 are executed 
 - the number of rules is the amount of times that a rule is created minus the amount of times a rule 
 - the number of rules must be smaller than the size of the grammar
   is deleted
 -  
 -->

---

## implementation - complexity 

<v-clicks>

- $a_2$: check for duplicate digrams
- with occupancy $\lt 80\%$ lookups are $\mathcal O (1)$
- hashtable size smaller than grammar (which itself is linearly bounded by the input)
- $a_2$ can only be executed, when either of $a_1, a_3 - a_5$ are run (bounded by $\mathcal O(n)$)

- $a_2$: check for duplicate digrams

</v-clicks>

<v-click>

$$\implies a_2 \in \mathcal O(n)$$

</v-click>

<v-click>

<center> 

**$\implies$ `sequitur` runs in $\mathcal O(n)$** 

</center>

</v-click>

<v-click>

*but*

</v-click>


<v-clicks>

- in theory the hashing and hence addressing will be $\mathcal O (\log n)$, remains stable up to $10^{19}$ symbols on 64bit 
  archs (10 Exabytes if 1 Byte per symbol is assumed)
- `sequitur` is also linear in memory

</v-clicks>

<!-- 
- size of input has to be known in advance - streaming? 
- table has to be resized on the fly? still linear?
- hashtable size smaller than grammar because 
  - digramcount is same as symbols in grammar 
  - 
-->

--- 
layout: figure
figureCaption: behaviour on English text; rules-symbols (a); grammar-symbols (b); vocabulary-symbols (c); time-symbols (d)
figureUrl: linear-behaviour.png
---

## implementation - complexity

--- 
layout: center
---

# evaluation

> how does `sequitur` perform?

--- 
layout: figure
figureUrl: sequitur-info-qr.png
figureCaption: http://sequitur.info - JS-implementation by C. Nevill-Manning
---

## evaluation - showcase 

---

## evaluation - comparison
<v-click>

<br>

> `sequitur` [..] outperfoms other schemes that achieve compression by factoring out repetition, and approaches performance of schemes that 
  compress based on probabilistic predictions

<br>

</v-click>

<v-clicks>

- *linear in time* (cf. `Mk10`, $\mathcal O(n^2)$, Wolff, 1975)

</v-clicks>


<v-click>

<br>

*but*

</v-click>

<v-clicks>

- linear in space 
  - split input; merge grammars 
  - $\mathcal O(\log n)$ memory 
  - sacrifices digram uniqueness)
- issues with hashtable 
  - resizing (to maintain amortized $\mathcal O(1)$ `lookup` and `insert`) is costly

</v-clicks>

<!-- 
- Wolffs algorithm forms sequitur rules if a digram is seen >10 times
-->

--- 

## evaluation - summary

<v-click>

Use two simple rules:
- **digram uniqueness**
- **rule utility**

</v-click>
<v-click>

to achieve algorithm that compresses...
- in $\mathcal O(n)$ **space** and **time**
- **losslessly**

</v-click>
<v-click>

which can be implemented...
- by the use of **doubly linked lists**
- and **hash tables**

</v-click>

--- 
layout: center
---

# Thank you for your attention

> questions welcome
