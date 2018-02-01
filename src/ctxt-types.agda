module ctxt-types where

open import lib
open import cedille-types
open import general-util
open import syntax-util

location : Set
location = string × posinfo -- file path and starting position in the file 

{- we will generally keep classifiers of variables in hnf in the ctxt, although
   we will not necessarily unfold recursive type definitions. -}

defScope : Set
defScope = 𝔹

localScope : defScope
localScope = tt

globalScope : defScope
globalScope = ff

defParams : Set
defParams = maybe params

data ctxt-info : Set where

  -- for declaring a variable to have a given type (with no definition)
  term-decl : type → ctxt-info

  -- for defining a variable to equal a term with a given type
  term-def : defParams → term → type → ctxt-info

  -- for untyped term definitions 
  term-udef : defParams → term → ctxt-info

  -- for declaring a variable to have a given kind (with no definition)
  type-decl : kind → ctxt-info

  -- for defining a variable to equal a type with a given kind
  type-def : defParams → type → kind → ctxt-info

  -- for defining a variable to equal a kind
  kind-def : params → params → kind → ctxt-info

  -- to rename a variable at any level to another
  rename-def : var → ctxt-info

  -- representing a declaration of a variable with no other information about it
  var-decl : ctxt-info

sym-info : Set
sym-info = ctxt-info × location

-- module filename, name, parameters, and qualifying substitution
mod-info : Set
mod-info = string × string × params × qualif

is-term-level : ctxt-info → 𝔹
is-term-level (term-decl _) = tt
is-term-level (term-def _ _ _) = tt
is-term-level (term-udef _ _) = tt
is-term-level _ = ff

data ctxt : Set where
  mk-ctxt : (mod : mod-info) →                     -- current module
            (syms : trie (string × 𝕃 string)) →    -- map each filename to its module name and the symbols declared in that file
            (i : trie sym-info) →                  -- map symbols (from Cedille files) to their ctxt-info and location
            (sym-occurrences : trie (𝕃 (var × posinfo × string))) →  -- map symbols to a list of definitions they occur in (and relevant file info)
            ctxt


ctxt-binds-var : ctxt → var → 𝔹
ctxt-binds-var (mk-ctxt (_ , _ , _ , q) _ i _) x = trie-contains q x || trie-contains i x

ctxt-var-decl : posinfo → var → ctxt → ctxt
ctxt-var-decl p v (mk-ctxt (mn , fn , ps , q) syms i symb-occs) =
  mk-ctxt (mn , fn , ps , (trie-insert q v (p % v , ArgsNil p))) syms (trie-insert i v (var-decl , (fn , p))) symb-occs

qualif-var : ctxt → var → var
qualif-var (mk-ctxt (_ , _ , _ , q) _ _ _) v with trie-lookup q v
...| just (v' , _) = v'
...| nothing = v

start-modname : start → string
start-modname (File _ _ mn _ _ _) = mn