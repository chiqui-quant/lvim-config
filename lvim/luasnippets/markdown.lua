local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local events = require("luasnip.util.events")
local ai = require("luasnip.nodes.absolute_indexer")
local extras = require("luasnip.extras")
local l = extras.lambda
local rep = extras.rep
local p = extras.partial
local m = extras.match
local n = extras.nonempty
local dl = extras.dynamic_lambda
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local conds = require("luasnip.extras.expand_conditions")
local postfix = require("luasnip.extras.postfix").postfix
local types = require("luasnip.util.types")
local parse = require("luasnip.util.parser").parse_snippet

-- Important: remember to exit snippets with trigger, otherwise
-- all tabstops will be kept in memory and that can cause
-- performance issues.

-- This is the get_visual function. Summary: If `SELECT_RAW` is populated
-- with a visual selection, the function returns an insert node whose initial
-- text is set to the visual selection. If `SELECT_RAW` is empty, the function simply returns an empty insert node.
local function get_visual(args, parent)
  if (#parent.snippet.env.SELECT_RAW > 0) then
    return sn(nil, i(1, parent.snippet.env.SELECT_RAW))
  else
    return sn(nil, i(1, ''))
  end
end

local ls = require("luasnip")

-- Math context detection (requires vimtex plugin)
-- Note: I tried both options but it was expensive in terms of performance for my pc
-- So I opted for more unusual triggers that can be used globally in the markdown file
-- rather than just inside the $ $
-- Alternatively, it may be possible to toggle on and off luasnip (but I still to figure it out)
-- local tex = {}
-- tex.in_mathzone = function() return vim.fn['vimtex#syntax#in_mathzone']() == 1 end
-- tex.in_text = function() return not tex.in_mathzone() end

-- Suggested: knowledge of regular expressions makes life much easier to understand what happens here
-- Return snippet tables
-- Note: I commented all the snippets with the LuaSnip format and prefered to parse my latex-suite snippets
return {
  -- _{0} and other digits after letters and closing delimiters i.e. | ) ] } but not in numbers like 100
  s({ trig = '([%a%|%)%]%}])(%d)', regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      "<>_{<>}",
      {
        f(function(_, snip) return snip.captures[1] end),
        f(function(_, snip) return snip.captures[2] end),
      }
    )
  ),

  -- e.g. Xfoun becomes X_{1},...,X_{n}
  -- Xun may be shorter but may cause more conflict
  s({ trig = '(%a)foun', regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      "<>_{1},\\ldots,<>_{n}",
      {
        f(function(_, snip) return snip.captures[1] end),
        f(function(_, snip) return snip.captures[1] end),
      }
    )
  ),
  -- same but starting from zero
  s({ trig = '(%a)fzun', regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      "<>_{0},\\ldots,<>_{n}",
      {
        f(function(_, snip) return snip.captures[1] end),
        f(function(_, snip) return snip.captures[1] end),
      }
    )
  ),
  -- comfortable typing of functions: e.g. fof -> f()
  s({ trig = '(%a)of', regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      "<>(<>)",
      {
        f(function(_, snip) return snip.captures[1] end),
        d(1, get_visual),
      }
    )
  ),


  -- Parse snippets from other engines
  -- ls.parser.parse_snippet({ trig = "mk", name = "Math" }, "\\( ${1:${TM_SELECTED_TEXT}} \\)$0"),

  -- Parsing my personal snippets from latex-suite (start first tabstop with $1)
  -- TODO: notice if there are no conflicts when writing quite normal text
  -- TODO: implement everything about regex with lua conditions above with the standard luasnip format
  -- Theorem, Definition, Corollary, Lemma, Proof, Example, Exercise, Proposition
  ls.parser.parse_snippet({ trig = "bf", wordTrig = true, snippetType = "autosnippet" }, "**$1**$2"),
  ls.parser.parse_snippet({ trig = "dff", wordTrig = true, snippetType = "autosnippet" }, "**Definition.** $1"),
  ls.parser.parse_snippet({ trig = "thm", wordTrig = true, snippetType = "autosnippet" }, "**Theorem.** $1"),
  ls.parser.parse_snippet({ trig = "crl", wordTrig = true, snippetType = "autosnippet" }, "**Corollary.** $1"),
  ls.parser.parse_snippet({ trig = "lmm", wordTrig = true, snippetType = "autosnippet" }, "**Lemma.** $1"),
  ls.parser.parse_snippet({ trig = "prf", wordTrig = true, snippetType = "autosnippet" }, "**Proof.** $1"),
  ls.parser.parse_snippet({ trig = "exx", wordTrig = true, snippetType = "autosnippet" }, "**Example.** $1"),
  ls.parser.parse_snippet({ trig = "exr", wordTrig = true, snippetType = "autosnippet" }, "**Exercise.** $1"),
  ls.parser.parse_snippet({ trig = "sltn", wordTrig = true, snippetType = "autosnippet" }, "**Solution.** $1"),
  ls.parser.parse_snippet({ trig = "prp", wordTrig = true, snippetType = "autosnippet" }, "**Proposition.** $1"),

  -- Math mode
  ls.parser.parse_snippet({ trig = "fm", wordTrig = true, snippetType = "autosnippet" }, "$$1$$2"),
  ls.parser.parse_snippet({ trig = "dm", wordTrig = true, snippetType = "autosnippet" }, "$$$1$$$2"),
  ls.parser.parse_snippet({ trig = "cd", wordTrig = true, snippetType = "autosnippet" }, "```$1 \n```"),
  ls.parser.parse_snippet({ trig = "cx", wordTrig = true, snippetType = "autosnippet" }, "`$1`$2"),
  ls.parser.parse_snippet({ trig = "qa", wordTrig = true, snippetType = "autosnippet" }, "\\quad "),

  -- Greeks (maybe figure out a better solution in the future)
  ls.parser.parse_snippet({ trig = "om", wordTrig = true, snippetType = "autosnippet" }, "\\omega"),
  ls.parser.parse_snippet({ trig = "Om", wordTrig = true, snippetType = "autosnippet" }, "\\Omega"),
  ls.parser.parse_snippet({ trig = "bt", wordTrig = true, snippetType = "autosnippet" }, "\\beta"),
  ls.parser.parse_snippet({ trig = "sg", wordTrig = true, snippetType = "autosnippet" }, "\\sigma"),
  ls.parser.parse_snippet({ trig = "Sg", wordTrig = true, snippetType = "autosnippet" }, "\\Sigma"),
  ls.parser.parse_snippet({ trig = "dlt", wordTrig = true, snippetType = "autosnippet" }, "\\delta"),
  ls.parser.parse_snippet({ trig = "lm", wordTrig = true, snippetType = "autosnippet" }, "\\lambda"),
  ls.parser.parse_snippet({ trig = "ps", wordTrig = true, snippetType = "autosnippet" }, "\\varepsilon"),
  ls.parser.parse_snippet({ trig = "vphi", wordTrig = true, snippetType = "autosnippet" }, "\\varphi"),
  ls.parser.parse_snippet({ trig = "ksi", wordTrig = true, snippetType = "autosnippet" }, "\\xi"),

  -- TODO: insert space after greek letters and symbols

  -- Operations
  ls.parser.parse_snippet({ trig = "txe", wordTrig = true, snippetType = "autosnippet" }, "\\text{$1}"),
  ls.parser.parse_snippet({ trig = "spp", wordTrig = true, snippetType = "autosnippet" }, "\\sup_{$1}$2"),
  ls.parser.parse_snippet({ trig = "nfi", wordTrig = true, snippetType = "autosnippet" }, "\\inf_{$1}$2"),
  ls.parser.parse_snippet({ trig = "sqr", wordTrig = true, snippetType = "autosnippet" }, "\\sqrt{$1}$2"),
  ls.parser.parse_snippet({ trig = "sr", wordTrig = false, snippetType = "autosnippet" }, "^{2}"),
  ls.parser.parse_snippet({ trig = "cb", wordTrig = false, snippetType = "autosnippet" }, "^{3}"),
  ls.parser.parse_snippet({ trig = "tp", wordTrig = false, snippetType = "autosnippet" }, "^{$1}$2"),
  ls.parser.parse_snippet({ trig = ";", wordTrig = false, snippetType = "autosnippet" }, "_{$1}$2"),
  ls.parser.parse_snippet({ trig = "nv", wordTrig = true, snippetType = "autosnippet" }, "_{-1}$1"),
  ls.parser.parse_snippet({ trig = "--", wordTrig = false, snippetType = "autosnippet" }, "^{-}$1"),
  ls.parser.parse_snippet({ trig = "++", wordTrig = false, snippetType = "autosnippet" }, "^{+}$1"),
  ls.parser.parse_snippet({ trig = "TT", wordTrig = false, snippetType = "autosnippet" }, "^{\\mathrm{T}}$1"),
  ls.parser.parse_snippet({ trig = "fr", wordTrig = true, snippetType = "autosnippet" }, "\\frac{$1}{$2}$3"),
  ls.parser.parse_snippet({ trig = "ee", wordTrig = true, snippetType = "autosnippet" }, "e^{$1}$2"),
  ls.parser.parse_snippet({ trig = "cj", wordTrig = false, snippetType = "autosnippet" }, "^{*}"),
  ls.parser.parse_snippet({ trig = "cv", wordTrig = false, snippetType = "autosnippet" }, "*"),

  -- TODO: all stuff with [a-zA-Z] etc.

  -- TODO: make visual operations work
  -- ls.parser.parse_snippet({ trig = "U", wordTrig = true, snippetType = "autosnippet" }, "\\underbrace{ ${VISUAL} }_{ $0 }"),

  -- Symbols
  ls.parser.parse_snippet({ trig = "oo", wordTrig = true, snippetType = "autosnippet" }, "\\infty"),
  ls.parser.parse_snippet({ trig = "poo", wordTrig = true, snippetType = "autosnippet" }, "+\\infty"),
  ls.parser.parse_snippet({ trig = "mn", wordTrig = true, snippetType = "autosnippet" }, "-"), -- more comfortable minus, but for the plus it's ok, "pl" may conflict
  ls.parser.parse_snippet({ trig = "xn", wordTrig = true, snippetType = "autosnippet" }, "x \\in $1"),
  ls.parser.parse_snippet({ trig = "x \\in n", wordTrig = true, snippetType = "autosnippet" }, "x_{n}"),
  ls.parser.parse_snippet({ trig = "inn", wordTrig = true, snippetType = "autosnippet" }, "\\in "),
  ls.parser.parse_snippet({ trig = "notin", wordTrig = true, snippetType = "autosnippet" }, "\\notin "),
  ls.parser.parse_snippet({ trig = "stk", wordTrig = true, snippetType = "autosnippet" }, "\\stackrel{$1}{${2:\\to}}"),
  ls.parser.parse_snippet({ trig = "sts", wordTrig = true, snippetType = "autosnippet" }, "\\substack{$1 \\\\ $2}"),
  ls.parser.parse_snippet({ trig = "emt", wordTrig = true, snippetType = "autosnippet" }, "\\emptyset"),
  ls.parser.parse_snippet({ trig = "qq", wordTrig = true, snippetType = "autosnippet" }, "\\{$1 \\}$2"),
  ls.parser.parse_snippet({ trig = "prd", wordTrig = true, snippetType = "autosnippet" },
    "\\displaystyle\\prod_{i=1}^{n}"), -- check if goes well
  ls.parser.parse_snippet({ trig = "pm", wordTrig = true, snippetType = "autosnippet" }, "\\pm"),
  ls.parser.parse_snippet({ trig = "...", wordTrig = true, snippetType = "autosnippet" }, "\\ldots"),
  ls.parser.parse_snippet({ trig = "geq", wordTrig = true, snippetType = "autosnippet" }, "\\geq "),
  ls.parser.parse_snippet({ trig = "leq", wordTrig = true, snippetType = "autosnippet" }, "\\leq "),
  ls.parser.parse_snippet({ trig = "frl", wordTrig = true, snippetType = "autosnippet" }, "\\forall \\ "),
  ls.parser.parse_snippet({ trig = "exs", wordTrig = true, snippetType = "autosnippet" }, "\\exists \\ "),
  ls.parser.parse_snippet({ trig = "simm", wordTrig = true, snippetType = "autosnippet" }, "\\sim "),
  ls.parser.parse_snippet({ trig = "nbl", wordTrig = true, snippetType = "autosnippet" }, "\\nabla "),
  ls.parser.parse_snippet({ trig = "tm", wordTrig = true, snippetType = "autosnippet" }, "\\times "),
  ls.parser.parse_snippet({ trig = "cd", wordTrig = true, snippetType = "autosnippet" }, "\\cdot "),
  ls.parser.parse_snippet({ trig = "vdts", wordTrig = true, snippetType = "autosnippet" }, "\\vdots "),
  ls.parser.parse_snippet({ trig = "Cup", wordTrig = true, snippetType = "autosnippet" },
    "\\displaystyle\\bigcup_{$1} $2"),
  ls.parser.parse_snippet({ trig = "Cap", wordTrig = true, snippetType = "autosnippet" },
    "\\displaystyle\\bigcap_{$1} $2"),
  ls.parser.parse_snippet({ trig = "bve", wordTrig = true, snippetType = "autosnippet" },
    "\\displaystyle\\bigvee_{$1} $2"),
  ls.parser.parse_snippet({ trig = "tto", wordTrig = true, snippetType = "autosnippet" }, "\\to "),
  ls.parser.parse_snippet({ trig = "tif", wordTrig = true, snippetType = "autosnippet" }, "\\to +\\infty"),
  ls.parser.parse_snippet({ trig = "qwe", wordTrig = true, snippetType = "autosnippet" }, "\\square"),
  ls.parser.parse_snippet({ trig = "ewq", wordTrig = true, snippetType = "autosnippet" }, "$(*)$"),
  ls.parser.parse_snippet({ trig = "otm", wordTrig = true, snippetType = "autosnippet" }, "\\otimes "),
  ls.parser.parse_snippet({ trig = "opl", wordTrig = true, snippetType = "autosnippet" }, "\\oplus "),
  ls.parser.parse_snippet({ trig = "mps", wordTrig = true, snippetType = "autosnippet" }, "\\mapsto "),
  ls.parser.parse_snippet({ trig = "sb", wordTrig = true, snippetType = "autosnippet" }, "\\subset "),
  ls.parser.parse_snippet({ trig = "subeq", wordTrig = true, snippetType = "autosnippet" }, "\\subseteq "),
  ls.parser.parse_snippet({ trig = "nc", wordTrig = true, snippetType = "autosnippet" }, "\\supset "),
  ls.parser.parse_snippet({ trig = "urw", wordTrig = true, snippetType = "autosnippet" }, "\\uparrow "),
  ls.parser.parse_snippet({ trig = "drw", wordTrig = true, snippetType = "autosnippet" }, "\\downarrow "),
  ls.parser.parse_snippet({ trig = "cmp", wordTrig = true, snippetType = "autosnippet" }, "\\circ "), -- composition
  ls.parser.parse_snippet({ trig = "mpl", wordTrig = true, snippetType = "autosnippet" }, "\\imples "),
  ls.parser.parse_snippet({ trig = "wg", wordTrig = true, snippetType = "autosnippet" }, "\\wedge "),
  ls.parser.parse_snippet({ trig = "andd", wordTrig = true, snippetType = "autosnippet" }, "\\vee "),
  ls.parser.parse_snippet({ trig = "grt", wordTrig = true, snippetType = "autosnippet" }, ">"),
  ls.parser.parse_snippet({ trig = "tl", wordTrig = true, snippetType = "autosnippet" }, "\\tilde{$1}$2"),
  ls.parser.parse_snippet({ trig = "brr", wordTrig = true, snippetType = "autosnippet" }, "\\bar{$1}$2"),
  ls.parser.parse_snippet({ trig = "ht", wordTrig = true, snippetType = "autosnippet" }, "\\hat{$1}$2"),
  ls.parser.parse_snippet({ trig = "mx", wordTrig = true, snippetType = "autosnippet" }, "\\max"),
  ls.parser.parse_snippet({ trig = "minn", wordTrig = true, snippetType = "autosnippet" }, "\\min"),
  ls.parser.parse_snippet({ trig = "pxe", wordTrig = true, snippetType = "autosnippet" }, "\\exp\\{$1\\}$2"),
  ls.parser.parse_snippet({ trig = "evl", wordTrig = true, snippetType = "autosnippet" }, "\\bigg\\vert_{$1}^{$2}"),

  -- Subscripts
  -- ls.parser.parse_snippet({ trig = "nn", wordTrig = true, snippetType = "autosnippet" }, "_{n}"),
  -- ls.parser.parse_snippet({ trig = "mm", wordTrig = true, snippetType = "autosnippet" }, "_{m}"),
  -- ls.parser.parse_snippet({ trig = "ii", wordTrig = true, snippetType = "autosnippet" }, "_{i}"),
  -- ls.parser.parse_snippet({ trig = "jj", wordTrig = true, snippetType = "autosnippet" }, "_{j}"),
  -- ls.parser.parse_snippet({ trig = "kk", wordTrig = true, snippetType = "autosnippet" }, "_{k}"),
  -- ls.parser.parse_snippet({ trig = "kk", wordTrig = true, snippetType = "autosnippet" }, "_{k}"),

  ls.parser.parse_snippet({ trig = "Xin", wordTrig = true, snippetType = "autosnippet" }, "X \\in "),
  ls.parser.parse_snippet({ trig = "Xii", wordTrig = true, snippetType = "autosnippet" }, "X_{i}"),
  ls.parser.parse_snippet({ trig = "Xt", wordTrig = true, snippetType = "autosnippet" }, "X_{t}"),
  ls.parser.parse_snippet({ trig = "Xn", wordTrig = true, snippetType = "autosnippet" }, "X_{n}"),
  ls.parser.parse_snippet({ trig = "Xk", wordTrig = true, snippetType = "autosnippet" }, "X_{k}"),
  ls.parser.parse_snippet({ trig = "Xj", wordTrig = true, snippetType = "autosnippet" }, "X_{j}"),
  ls.parser.parse_snippet({ trig = "xii", wordTrig = true, snippetType = "autosnippet" }, "x_{i}"),
  ls.parser.parse_snippet({ trig = "xp1", wordTrig = true, snippetType = "autosnippet" }, "x_{n+1}"),
  ls.parser.parse_snippet({ trig = "Yt", wordTrig = true, snippetType = "autosnippet" }, "Y_{t}"),
  ls.parser.parse_snippet({ trig = "Yn", wordTrig = true, snippetType = "autosnippet" }, "Y_{n}"),
  ls.parser.parse_snippet({ trig = "Yj", wordTrig = true, snippetType = "autosnippet" }, "Y_{j}"),
  ls.parser.parse_snippet({ trig = "Yk", wordTrig = true, snippetType = "autosnippet" }, "Y_{k}"),
  ls.parser.parse_snippet({ trig = "Yi", wordTrig = true, snippetType = "autosnippet" }, "Y_{i}"),
  ls.parser.parse_snippet({ trig = "ynn", wordTrig = true, snippetType = "autosnippet" }, "y_{n}"),
  ls.parser.parse_snippet({ trig = "yii", wordTrig = true, snippetType = "autosnippet" }, "y_{i}"),
  ls.parser.parse_snippet({ trig = "yjj", wordTrig = true, snippetType = "autosnippet" }, "y_{j}"),
  ls.parser.parse_snippet({ trig = "Spo", wordTrig = true, snippetType = "autosnippet" }, "S_{n+1}"),
  ls.parser.parse_snippet({ trig = "Xpo", wordTrig = true, snippetType = "autosnippet" }, "X_{n+1}"),
  ls.parser.parse_snippet({ trig = "Ypo", wordTrig = true, snippetType = "autosnippet" }, "Y_{n+1}"),
  ls.parser.parse_snippet({ trig = "Xmo", wordTrig = true, snippetType = "autosnippet" }, "X_{n-1}"),

  ls.parser.parse_snippet({ trig = "Hn", wordTrig = true, snippetType = "autosnippet" }, "H_{n}"),
  ls.parser.parse_snippet({ trig = "Fn", wordTrig = true, snippetType = "autosnippet" }, "F_{n}"),
  ls.parser.parse_snippet({ trig = "Fn", wordTrig = true, snippetType = "autosnippet" }, "F_{n}"),
  ls.parser.parse_snippet({ trig = "Sn", wordTrig = true, snippetType = "autosnippet" }, "S_{n}"),
  ls.parser.parse_snippet({ trig = "Sk", wordTrig = true, snippetType = "autosnippet" }, "S_{k}"),
  ls.parser.parse_snippet({ trig = "fn", wordTrig = true, snippetType = "autosnippet" }, "f_{n}"),

  -- Special letters
  ls.parser.parse_snippet({ trig = "lbd", wordTrig = true, snippetType = "autosnippet" }, "\\mathscr{L}"),
  ls.parser.parse_snippet({ trig = "cnt", wordTrig = true, snippetType = "autosnippet" }, "\\mathscr{C}"),
  ls.parser.parse_snippet({ trig = "MM", wordTrig = true, snippetType = "autosnippet" }, "\\mathcal{$1}$2"),
  ls.parser.parse_snippet({ trig = "lll", wordTrig = true, snippetType = "autosnippet" }, "\\ell"),
  ls.parser.parse_snippet({ trig = "AA", wordTrig = true, snippetType = "autosnippet" }, "\\mathcal{A}"),
  ls.parser.parse_snippet({ trig = "BB", wordTrig = true, snippetType = "autosnippet" }, "\\mathcal{B}"),
  ls.parser.parse_snippet({ trig = "BR", wordTrig = true, snippetType = "autosnippet" }, "\\mathcal{B}_{\\mathbb{R}}"),
  ls.parser.parse_snippet({ trig = "GG", wordTrig = true, snippetType = "autosnippet" }, "\\mathcal{G}"),
  ls.parser.parse_snippet({ trig = "LL", wordTrig = true, snippetType = "autosnippet" }, "\\mathcal{L}"),
  ls.parser.parse_snippet({ trig = "HH", wordTrig = true, snippetType = "autosnippet" }, "\\mathcal{H}"),
  ls.parser.parse_snippet({ trig = "FF", wordTrig = true, snippetType = "autosnippet" }, "\\mathcal{F}"),
  ls.parser.parse_snippet({ trig = "\\mathcal{F}n", wordTrig = true, snippetType = "autosnippet" }, "\\mathcal{F}_{n}"),
  ls.parser.parse_snippet({ trig = "\\mathcal{F}i", wordTrig = true, snippetType = "autosnippet" }, "\\mathcal{F}_{i}"),
  ls.parser.parse_snippet({ trig = "\\mathcal{F}t", wordTrig = true, snippetType = "autosnippet" }, "\\mathcal{F}_{t}"),
  ls.parser.parse_snippet({ trig = "\\mathcal{F}s", wordTrig = true, snippetType = "autosnippet" }, "\\mathcal{F}_{s}"),
  ls.parser.parse_snippet({ trig = "\\mathcal{F}T", wordTrig = true, snippetType = "autosnippet" }, "\\mathcal{F}_{T}"),
  ls.parser.parse_snippet({ trig = "\\mathcal{F}S", wordTrig = true, snippetType = "autosnippet" }, "\\mathcal{F}_{S}"),
  ls.parser.parse_snippet({ trig = "\\mathcal{F}K", wordTrig = true, snippetType = "autosnippet" }, "\\mathcal{F}_{K}"),
  ls.parser.parse_snippet({ trig = "CC", wordTrig = true, snippetType = "autosnippet" }, "\\mathbb{C}"),
  ls.parser.parse_snippet({ trig = "EE", wordTrig = true, snippetType = "autosnippet" }, "\\mathbb{E}"),
  ls.parser.parse_snippet({ trig = "PP", wordTrig = true, snippetType = "autosnippet" }, "\\mathbb{P}"),
  ls.parser.parse_snippet({ trig = "NN", wordTrig = true, snippetType = "autosnippet" }, "\\mathbb{N}"),
  ls.parser.parse_snippet({ trig = "ZZ", wordTrig = true, snippetType = "autosnippet" }, "\\mathbb{Z}"),
  ls.parser.parse_snippet({ trig = "QQ", wordTrig = true, snippetType = "autosnippet" }, "\\mathbb{Q}"),
  ls.parser.parse_snippet({ trig = "RR", wordTrig = true, snippetType = "autosnippet" }, "\\mathbb{R}"),
  ls.parser.parse_snippet({ trig = "RN", wordTrig = true, snippetType = "autosnippet" }, "\\mathbb{R}^{N}"),
  ls.parser.parse_snippet({ trig = "ndc", wordTrig = true, snippetType = "autosnippet" }, "\\mathbb{1}_{$1}$2"),
  ls.parser.parse_snippet({ trig = "nds", wordTrig = true, snippetType = "autosnippet" }, "\\mathbb{1}_{$1}$2"),

  -- Lebesgue spaces
  ls.parser.parse_snippet({ trig = "Lone", wordTrig = true, snippetType = "autosnippet" }, "L^{1}"),
  ls.parser.parse_snippet({ trig = "Ltwo", wordTrig = true, snippetType = "autosnippet" }, "L^{2}"),
  ls.parser.parse_snippet({ trig = "Loo", wordTrig = true, snippetType = "autosnippet" }, "L^{\\infty}"),
  ls.parser.parse_snippet({ trig = "Lp", wordTrig = true, snippetType = "autosnippet" }, "L^{p}"),
  ls.parser.parse_snippet({ trig = "Lq", wordTrig = true, snippetType = "autosnippet" }, "L^{q}"),

  -- Limits
  ls.parser.parse_snippet({ trig = "limm", wordTrig = true, snippetType = "autosnippet" },
    "\\lim\\limits_{${1:n} \\to ${2:\\infty}} $3"),
  ls.parser.parse_snippet({ trig = "linn", wordTrig = true, snippetType = "autosnippet" }, "\\lim\\limits_{n} "),
  ls.parser.parse_snippet({ trig = "lsup", wordTrig = true, snippetType = "autosnippet" }, "\\limsup\\limits "),

  -- Sums
  ls.parser.parse_snippet({ trig = "ss", wordTrig = true, snippetType = "autosnippet" },
    "\\displaystyle\\sum_{${1:i=1}}^{${2:n}} $3"),
  ls.parser.parse_snippet({ trig = "sinf", wordTrig = true, snippetType = "autosnippet" },
    "\\displaystyle\\sum_{${1:n=1}}^{\\infty} $2"),
  ls.parser.parse_snippet({ trig = "sunn", wordTrig = true, snippetType = "autosnippet" }, "\\displaystyle\\sum_{n} $1"),
  ls.parser.parse_snippet({ trig = "suii", wordTrig = true, snippetType = "autosnippet" }, "\\displaystyle\\sum_{i} $1"),
  ls.parser.parse_snippet({ trig = "sujj", wordTrig = true, snippetType = "autosnippet" }, "\\displaystyle\\sum_{j} $1"),
  ls.parser.parse_snippet({ trig = "sukk", wordTrig = true, snippetType = "autosnippet" }, "\\displaystyle\\sum_{k} $1"),
  ls.parser.parse_snippet({ trig = "sux", wordTrig = true, snippetType = "autosnippet" }, "\\displaystyle\\sum_{x} $1"),

  -- Derivatives
  ls.parser.parse_snippet({ trig = "pard", wordTrig = true, snippetType = "autosnippet" },
    "\\frac{ \\partial ${1:y} }{ \\partial ${2:x} } $3"),
  ls.parser.parse_snippet({ trig = "par2", wordTrig = true, snippetType = "autosnippet" },
    "\\frac{ \\partial^{2} ${1:y} }{ \\partial ${2:x}^{2} } $3"),
  ls.parser.parse_snippet({ trig = "par3", wordTrig = true, snippetType = "autosnippet" },
    "\\frac{ \\partial^{3} ${1:y} }{ \\partial ${2:x}^{3} } $3"),
  ls.parser.parse_snippet({ trig = "ddt", wordTrig = true, snippetType = "autosnippet" }, "\\frac{d}{dt}"),
  ls.parser.parse_snippet({ trig = "ddv", wordTrig = true, snippetType = "autosnippet" }, "\\frac{d$1}{d$2}"),

  -- Integrals
  ls.parser.parse_snippet({ trig = "intt", wordTrig = true, snippetType = "autosnippet" }, "\\displaystyle\\int_{$1} $2"),
  ls.parser.parse_snippet({ trig = "dint", wordTrig = true, snippetType = "autosnippet" },
    "\\displaystyle\\int_{${1:-\\infty}}^{${2:\\infty}} $3"),

  -- Convergence
  ls.parser.parse_snippet({ trig = "a.s", wordTrig = true, snippetType = "autosnippet" },
    "\\stackrel{\\text{a.s.}}{\\to} "),
  ls.parser.parse_snippet({ trig = "c.w", wordTrig = true, snippetType = "autosnippet" }, "\\stackrel{\\text{w}}{\\to} "),
  ls.parser.parse_snippet({ trig = "c.p", wordTrig = true, snippetType = "autosnippet" },
    "\\stackrel{\\mathbb{P}}{\\to} "),
  ls.parser.parse_snippet({ trig = "c.d", wordTrig = true, snippetType = "autosnippet" }, "\\stackrel{\\text{d}}{\\to} "),
  ls.parser.parse_snippet({ trig = "c.lp", wordTrig = true, snippetType = "autosnippet" }, "\\stackrel{L^{p}}{\\to} "),
  ls.parser.parse_snippet({ trig = "c.l1", wordTrig = true, snippetType = "autosnippet" }, "\\stackrel{L^{1}}{\\to} "),
  ls.parser.parse_snippet({ trig = "c.l2", wordTrig = true, snippetType = "autosnippet" }, "\\stackrel{L^{2}}{\\to} "),

  -- Spaces
  ls.parser.parse_snippet({ trig = "psp", wordTrig = true, snippetType = "autosnippet" },
    "(\\Omega, \\mathcal{H}, \\mathbb{P})"), -- probabilty space
  ls.parser.parse_snippet({ trig = "mse", wordTrig = true, snippetType = "autosnippet" }, "$(E, \\mathcal{E})$"), -- measurable space E, curly E
  ls.parser.parse_snippet({ trig = "msf", wordTrig = true, snippetType = "autosnippet" }, "$(F, \\mathcal{F})$"),
  ls.parser.parse_snippet({ trig = "nsp", wordTrig = true, snippetType = "autosnippet" },
    "(${1:X}, ${2:\\lVert \\cdot \\rVert})"), -- normed space
  ls.parser.parse_snippet({ trig = "hsp", wordTrig = true, snippetType = "autosnippet" },
    "$(H,\\langle \\cdot,\\cdot \\rangle)$ "), -- Hilbert space H


  -- Environments
  ls.parser.parse_snippet({ trig = "csc", wordTrig = true, snippetType = "autosnippet" },
    "\\begin{cases} $1 & $2 \\\\ $3 & $4 \\end{cases}"),
  ls.parser.parse_snippet({ trig = ",,", wordTrig = true, snippetType = "autosnippet" }, "& "),

  -- Brackets
  ls.parser.parse_snippet({ trig = "nr", wordTrig = true, snippetType = "autosnippet" }, "\\lVert $1 \\rVert$2"),
  ls.parser.parse_snippet({ trig = "bs", wordTrig = true, snippetType = "autosnippet" }, "|$1|$2"),
  ls.parser.parse_snippet({ trig = "o(", wordTrig = true, snippetType = "autosnippet" }, "($1]$2"),
  ls.parser.parse_snippet({ trig = "b(", wordTrig = true, snippetType = "autosnippet" }, "[$1)$2"),

  -- Practical stuff for lectures
  ls.parser.parse_snippet({ trig = "tayl", wordTrig = true, snippetType = "autosnippet" },
    "${0:f}(${1:x} + ${2:h}) = ${0:f}(${1:x}) + ${0:f}'(${1:x})${2:h} + ${0:f}''(${1:x}) \\frac{${2:h}^{2}}{2!} + \\dots$3"),
  ls.parser.parse_snippet({ trig = "ucont", wordTrig = true, snippetType = "autosnippet" },
    "$\\forall \\ \\varepsilon >0$, $\\exists \\ \\delta >0$ "),
  ls.parser.parse_snippet({ trig = "slg", wordTrig = true, snippetType = "autosnippet" }, "$\\sigma$-algebra"),
  ls.parser.parse_snippet({ trig = "sfn", wordTrig = true, snippetType = "autosnippet" }, "$\\sigma$-finite"),
  ls.parser.parse_snippet({ trig = "sfn", wordTrig = true, snippetType = "autosnippet" }, "$\\sigma$-finite"),
  ls.parser.parse_snippet({ trig = "X,o", wordTrig = true, snippetType = "autosnippet" }, "X(\\omega)"),
  ls.parser.parse_snippet({ trig = "EF", wordTrig = true, snippetType = "autosnippet" }, "\\mathbb{E}_{\\mathcal{F}}"),
  ls.parser.parse_snippet({ trig = "CE", wordTrig = true, snippetType = "autosnippet" }, "\\mathbb{E}[$0|$1]$2"),
  ls.parser.parse_snippet({ trig = "oiO", wordTrig = true, snippetType = "autosnippet" }, "\\omega \\in \\Omega"),
  ls.parser.parse_snippet({ trig = "cjp", wordTrig = true, snippetType = "autosnippet" }, "\\frac{1}{p}+\\frac{1}{q}=1"),
  ls.parser.parse_snippet({ trig = "ty", wordTrig = true, snippetType = "autosnippet" }, "\\tau_{y}"),
  ls.parser.parse_snippet({ trig = "sps", wordTrig = true, snippetType = "autosnippet" }, "(X_{t})_{t \\in T}"),
  ls.parser.parse_snippet({ trig = "tit", wordTrig = true, snippetType = "autosnippet" }, "t \\in T"),
  ls.parser.parse_snippet({ trig = "nin", wordTrig = true, snippetType = "autosnippet" }, "n \\in \\mathbb{N}"),

  -- Probability distributions
  ls.parser.parse_snippet({ trig = "gss", wordTrig = true, snippetType = "autosnippet" },
    "\\frac{1}{\\sigma\\sqrt{ 2\\pi }}\\exp \\left\\{ -\\frac{(x-\\mu)^{2}}{2\\sigma^{2}} \\right\\}"),

  -- Special cases to deal with conflicts
  ls.parser.parse_snippet({ trig = "f_{n}t", wordTrig = true, snippetType = "autosnippet" }, "<+\\infty"),

}
