
# 🎲 Dice Language Grammar – Specification

## 🧭 Overview

This specification defines a custom **dice-rolling expression language** for tabletop RPGs and narrative-driven systems. It supports:

- Standard dice (`2d6+3`)
- Dice pools with thresholds (`10d6 >= 5`)
- Keep/Drop modifiers (`4d6kh3`)
- Exploding dice (`d6!`)
- Named variables (`damage = 2d6+4`)
- Random tables with weights and nesting
- Tagged dice for outcome evaluation (e.g., `hope: d12, fear: d12`)

---

## 📐 1. Core Dice Rolls

### Syntax

```
XdY
```

- `X` = number of dice (default = 1 if omitted)
- `Y` = sides per die

### Examples

- `d20` → one 20-sided die
- `2d6` → two 6-sided dice

---

## ➕ 2. Arithmetic Modifiers

### Supported Operators

```
+  -  *  /
```

### Grouping

Use parentheses for order of operations:

- `(2d6+3)*2`

---

## 💥 3. Exploding Dice

- `!` → explode on max value
- `!!` → compound explode (recursive)

### Examples

- `d6!` → roll again if 6
- `4d10!!` → chain additional rolls

---

## 🎯 4. Dice Pools

### Syntax

```
XdY >= N
```

- Compare each die to a threshold
- Count how many are successful

### Examples

- `8d6 >= 5` → number of dice ≥ 5
- `10d10 > 7` → count dice > 7

---

## 🧊 5. Keep / Drop Mechanics

### Long Form

- `keep highest N`
- `drop lowest N`

### Short Form

- `khN`, `klN`, `dhN`, `dlN`

### Examples

- `4d6kh3` → roll 4 dice, keep top 3
- `5d10 drop lowest` → keep 4 highest

---

## 🧪 6. Tagged Dice & Grouped Rolls

### Syntax

```text
[tag1: dX, tag2: dY] => outcome_rule
```

### Outcome Rule Keywords

- `higher_tag determines outcome`
- Custom evaluators (future)

### Example

```text
[hope: d12, fear: d12] => higher_tag determines outcome
```

#### Output

```json
{
  "hope": 9,
  "fear": 6,
  "sum": 15,
  "higher_tag": "hope",
  "outcome": "hopeful"
}
```

---

## 📋 7. Random Tables

### Table Definition

```text
@table_name
1-2: Goblins
3-4: Wolves
5: Ancient Ruins → @ruins_table
6-10: Nothing
```

### Table Weights

```text
@loot_table
50%: 1d6 silver
30%: Minor potion → @potions
20%: Rare item
```

### Lookup Syntax

- `@table_name`
- Nested reference: `→ @sub_table`

---

## 🗂️ 8. Named Variables

### Variable Declaration Syntax

```text
variable_name = expression
```

- **Assignment operator**: `=` (single equals)
- **Variable names**: Follow identifier rules (letters, numbers, underscores)
- **Scope**: Session-based (variables persist across evaluations)

### Variable Reference Syntax

```text
variable_name
```

- Variables are referenced by name as primary expressions
- **Lazy evaluation**: Expressions are re-evaluated each time referenced
- **Immutable**: Once declared, variables cannot be reassigned

### Examples

#### Basic Declaration and Reference
```text
damage = 2d6+4
attack = damage + 3
```

#### Complex Expressions
```text
strength_modifier = (strength - 10) / 2
attack_roll = d20 + strength_modifier
damage_roll = 2d6 + strength_modifier
```

#### Variables with Dice Modifiers
```text
advantage = 2d20kh1
sneak_attack = 3d6!
total_damage = damage_roll + sneak_attack
```

### Behavior Notes

- **Lazy Evaluation**: Each variable reference re-evaluates the stored expression
- **Dice Randomness**: Variables containing dice will produce different results on each reference
- **Immutability**: Variables cannot be redeclared or modified once set
- **Session Scope**: Variables persist within the same evaluation context

---

## 🧮 9. Grammar (EBNF)

```ebnf
program           ::= statement_list
statement_list    ::= statement (newline statement)*
statement         ::= variable_declaration | expression

variable_declaration ::= identifier "=" expression
variable_reference   ::= identifier

expression        ::= roll | pool | arithmetic_expr | table_lookup | grouped_expr | tagged_group | variable_reference

roll              ::= [count] "d" sides [exploding] [keep_drop] [threshold]
pool              ::= count "d" sides threshold [exploding]
threshold         ::= (">=" | "<=" | ">" | "<") number
arithmetic_expr   ::= expression operator number | expression operator expression
grouped_expr      ::= "(" expression ")"
keep_drop         ::= ("kh" | "kl" | "dh" | "dl") number | ("keep" | "drop") ("highest" | "lowest") number
exploding         ::= "!" | "!!"
operator          ::= "+" | "-" | "*" | "/"

tagged_group      ::= "[" tagged_roll ("," tagged_roll)* "]" [ "=>" outcome_rule ]
tagged_roll       ::= tag ":" roll
tag               ::= identifier
outcome_rule      ::= "higher_tag determines outcome" | custom_rule

table_lookup      ::= "@" identifier | entry_line
entry_line        ::= weight ":" result_text [reference]
reference         ::= "→" "@" identifier
weight            ::= number | range | percent
result_text       ::= string [embedded_rolls]

identifier        ::= letter (letter | digit | "_")*
range             ::= number "-" number
percent           ::= number "%"
count             ::= integer
sides             ::= integer | "%" | "F"
number            ::= integer
```

---

## 🧾 10. Output Format (Example)

```json
{
  "type": "tagged_group",
  "raw": "[hope: d12, fear: d12]",
  "rolls": {
    "hope": 10,
    "fear": 6
  },
  "sum": 16,
  "higher_tag": "hope",
  "outcome": "hopeful"
}
```

---

## 🔮 11. Optional / Future Features

- Macros or presets: `@greatsword_attack`
- Conditional logic in tables
- Tagged dice in pools (`3d6[tag=chaos]`)
- Comments: `# this is a note`
- Variable reassignment with `let`/`var` keywords
- Function definitions

---

## ✅ 12. Acceptance Criteria

| Feature | Requirement |
|--------|-------------|
| 🎲 Standard Dice Rolls | `2d6`, `d20` |
| ➕ Modifiers | Arithmetic expressions, parentheses |
| 💥 Exploding Dice | `!`, `!!` |
| 🎯 Dice Pools | Threshold success counting |
| 🧊 Keep/Drop Mechanics | `kh`, `kl`, `dh`, `dl` |
| 🧪 Tagged Dice | Named dice rolls with logic |
| 📋 Random Tables | Ranges, weights, references |
| 🗂️ Named Variables | Declaration, reference, lazy evaluation |
| 🧮 Grammar | Formal grammar definition |
| 📤 Structured Output | JSON format with breakdowns |

---

## 📎 13. Version

**Spec Version:** 1.1  
**Last Updated:** 2025-07-13  
**Maintainer:** DiceLang Development Team

### Changelog

**v1.1 (2025-07-13)**
- Added named variables with declaration and reference syntax
- Extended grammar to support variable statements
- Added lazy evaluation semantics for variables
- Enhanced acceptance criteria

**v1.0 (2025-07-05)**
- Initial specification release
- Core dice rolling features
- Tagged dice and random tables
