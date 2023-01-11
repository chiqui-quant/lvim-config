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


-- local rec_ls
-- rec_ls = function()
--   return sn(nil, {
--     c(1, {
--       -- important!! Having the sn(...) as the first choice will cause infinite recursion.
--       t({ "" }),
--       -- The same dynamicNode as in the snippet (also note: self reference).
--       sn(nil, { t({ "", "\t\\item " }), i(1), d(2, rec_ls, {}) }),
--     }),
--   });
-- end

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
return {
  -- This is just a test
  -- s("ls", {
  --   t({ "\\begin{itemize}",
  --     "\t\\item " }), i(1), d(2, rec_ls, {}),
  --   t({ "", "\\end{itemize}" }), i(0)
  -- }),
  -- SUBSCRIPTS and SUPERSCRIPTS
  -- SUPERSCRIPT: eg. type ' after a parenthesis () and you will have ()^{}
  s({ trig = "([%w%)%]%}%|])'", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta(
      "<>^{<>}",
      {
        f(function(_, snip) return snip.captures[1] end),
        d(1, get_visual),
      }
    )
  ),
  -- SUBSCRIPT
  s({ trig = "([%w%)%]%}]);", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta(
      "<>_{<>}",
      {
        f(function(_, snip) return snip.captures[1] end),
        d(1, get_visual),
      }
    )
  ),
  -- SUBSCRIPT AND SUPERSCRIPT
  s({ trig = "([%w%)%]%}])__", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta(
      "<>^{<>}_{<>}",
      {
        f(function(_, snip) return snip.captures[1] end),
        i(1),
        i(2),
      }
    )
  ),
  -- TEXT SUBSCRIPT
  s({ trig = 'sd', snippetType = "autosnippet", wordTrig = false },
    fmta("_{\\mathrm{<>}}",
      { d(1, get_visual) }
    )
  ),
  -- SUPERSCRIPT SHORTCUT
  -- Places the first alphanumeric character after the trigger into a superscript.
  -- e.g. a"2 becomes a^{2}
  s({ trig = '([%w%)%]%}])"([%w])', regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      "<>^{<>}",
      {
        f(function(_, snip) return snip.captures[1] end),
        f(function(_, snip) return snip.captures[2] end),
      }
    )
  ),
  -- SUBSCRIPT SHORTCUT
  -- Places the first alphanumeric character after the trigger into a subscript.
  -- e.g. a:z becomes a_{z}
  s({ trig = '([%w%)%]%}]):([%w])', regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      "<>_{<>}",
      {
        f(function(_, snip) return snip.captures[1] end),
        f(function(_, snip) return snip.captures[2] end),
      }
    )
  ),
  -- MINUS ONE SUPERSCRIPT SHORTCUT (TO CHANGE conflicts with a1 to a_1)
  s({ trig = '([%a%)%]%}])11', regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      "<>_{<>}",
      {
        f(function(_, snip) return snip.captures[1] end),
        t("-1")
      }
    )
  ),
  -- J SUBSCRIPT SHORTCUT (since jk triggers snippet jump forward)
  s({ trig = '([%a%)%]%}])JJ', wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta(
      "<>_{<>}",
      {
        f(function(_, snip) return snip.captures[1] end),
        t("j")
      }
    )
  ),
  -- PLUS SUPERSCRIPT SHORTCUT
  s({ trig = '([%a%)%]%}])%+%+', regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      "<>^{<>}",
      {
        f(function(_, snip) return snip.captures[1] end),
        t("+")
      }
    )
  ),
  -- COMPLEMENT SUPERSCRIPT: xcc becomes x^{\complement}
  -- TODO:same for transpose
  s({ trig = '([%a%)%]%}])cc', regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      "<>^{<>}",
      {
        f(function(_, snip) return snip.captures[1] end),
        t("C")
      }
    )
  ),
  -- CONJUGATE (STAR) SUPERSCRIPT SHORTCUT: x** becomes x^{*}
  s({ trig = '([%a%)%]%}])%*%*', regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      "<>^{<>}",
      {
        f(function(_, snip) return snip.captures[1] end),
        t("*")
      }
    )
  ),
  -- Expand ee to e^{} after spaces, delimiters and so on but not in words like "see", "feel" etc.
  s({ trig = '([^%a])ee', regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      "<>e^{<>}",
      {
        f(function(_, snip) return snip.captures[1] end),
        d(1, get_visual)
      }
    )
  ),
  -- _{0} after letters and closing delimiters i.e. | ) ] } but not in numbers like 100
  s({ trig = '([%a%|%)%]%}])0', regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      "<>_{<>}",
      {
        f(function(_, snip) return snip.captures[1] end),
        t("0")
      }
    )
  ),
  -- type ; after brackets to have _{}
  -- figure out how to make it work without conflict of normal text in markdown (math context vs not)
  s({ trig = "([%)%]%}]);", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta(
      "<>_{<>}",
      {
        f(function(_, snip) return snip.captures[1] end),
        d(1, get_visual),
      }
    )
  ),
  -- FONTS and TEXT (mathbb and mathcal)
  -- MATH BLACKBOARD i.e. \mathbb
  s({ trig = "([^%a])mbb", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      "<>\\mathbb{<>}",
      {
        f(function(_, snip) return snip.captures[1] end),
        d(1, get_visual),
      }
    )
  ),
  -- MATH CALIGRAPHY i.e. \mathcal
  s({ trig = "([^%a])mcc", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      "<>\\mathcal{<>}",
      {
        f(function(_, snip) return snip.captures[1] end),
        d(1, get_visual),
      }
    )
  ),
  -- REGULAR TEXT i.e. \text
  s({ trig = "([^%a])tee", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      "<>\\text{<>}",
      {
        f(function(_, snip) return snip.captures[1] end),
        d(1, get_visual),
      }
    )
  ),
  -- GENERAL MATHEMATICAL NOTATION
  -- Absolute value
  s({ trig = "([^%a])aa", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      "<>\\left| <> \\right|",
      {
        f(function(_, snip) return snip.captures[1] end),
        d(1, get_visual),
      }
    )
  ),
  -- Angle brackets
  s({ trig = "([^%a])lng", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      "<>\\langle <> \\rangle",
      {
        f(function(_, snip) return snip.captures[1] end),
        d(1, get_visual),
      }
    )
  ),
  -- Norm
  s({ trig = "([^%a])nr", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      "<>\\left\\lVert <> \\right\\rVert",
      {
        f(function(_, snip) return snip.captures[1] end),
        d(1, get_visual),
      }
    )
  ),
  -- Expand ff to \frac{}{} but not in words
  s({ trig = '([^%a])ff', regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      [[<>\frac{<>}{<>}]],
      {
        f(function(_, snip) return snip.captures[1] end),
        i(1),
        i(2)
      }
    )
  ),
  -- Bar (ideally use math mode)
  s({ trig = "([^%a])bbb", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      "<>\\bar_{<>}",
      {
        f(function(_, snip) return snip.captures[1] end),
        d(1, get_visual),
      }
    )
  ),
  -- Hat
  s({ trig = "([^%a])ht", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      "<>\\hat_{<>}",
      {
        f(function(_, snip) return snip.captures[1] end),
        d(1, get_visual),
      }
    )
  ),
  -- Overline
  s({ trig = "([^%a])ovl", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      "<>\\overline_{<>}",
      {
        f(function(_, snip) return snip.captures[1] end),
        d(1, get_visual),
      }
    )
  ),
  -- Tilde
  s({ trig = "([^%a])til", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      "<>\\tilde{<>}",
      {
        f(function(_, snip) return snip.captures[1] end),
        d(1, get_visual),
      }
    )
  ),
  -- Dot derivative notation
  s({ trig = "([^%a])dot", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      "<>\\dot{<>}",
      {
        f(function(_, snip) return snip.captures[1] end),
        d(1, get_visual),
      }
    )
  ),
  -- SQUARE ROOT
  s({ trig = "([^%\\])sq", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta(
      "<>\\sqrt{<>}",
      {
        f(function(_, snip) return snip.captures[1] end),
        d(1, get_visual),
      }
    )
  ),
  -- BINOMIAL SYMBOL
  s({ trig = "([^%\\])bnn", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta(
      "<>\\binom{<>}{<>}",
      {
        f(function(_, snip) return snip.captures[1] end),
        i(1),
        i(2),
      }
    )
  ),
  -- LOGARITHM WITH BASE SUBSCRIPT
  s({ trig = "([^%a%\\])lg", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta(
      "<>\\log_{<>}",
      {
        f(function(_, snip) return snip.captures[1] end),
        i(1),
      }
    )
  ),
  -- Spaces
  s({ trig = "LL", snippetType = "autosnippet" },
    {
      t("& "),
    }
  ),
  s({ trig = "q" }, -- needs to be manually triggered
    {
      t("\\quad "),
    }
  ),
  s({ trig = "qq", snippetType = "autosnippet" },
    {
      t("\\qquad "),
    }
  ),
  -- Infinity
  s({ trig = "inff", snippetType = "autosnippet" },
    {
      t("\\infty"),
    }
  ),
  -- inn becomes \in \mathbb{R} (default option, press tab to keep it or write to change it)
  -- s({trig="([^%a])inn", regTrig=true, wordTrig = false, snippetType="autosnippet"},
  --   fmta(
  --     [[<>\in <>]],
  --     {
  --       f( function(_, snip) return snip.captures[1] end ),
  --       i(1, "\\mathbb{R}"),
  --     }
  --   )
  -- ),
  s({ trig = "inn", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      [[<>\in ]],
      {
        f(function(_, snip) return snip.captures[1] end),
        -- i(1, "\\mathbb{R}"),
      }
    )
  ),
  -- not in
  s({ trig = "([^%a])notin", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      [[<>\notin {<>}]],
      {
        f(function(_, snip) return snip.captures[1] end),
        i(1, "\\mathbb{R}"),
      }
    )
  ),
  -- xn becomes x \in \
  s({ trig = "([^%a])xnn", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      [[<>x \in <>]],
      {
        f(function(_, snip) return snip.captures[1] end),
        d(1, get_visual),
      }
    )
  ),
  s({ trig = "([^%a])mcal", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      [[<>\mathcal{<>}]],
      {
        f(function(_, snip) return snip.captures[1] end),
        d(1, get_visual),
      }
    )
  ),

  -- Mappazzone veloce TODO: implementare meglio regular expressions (soluzioni rapide ma non ottimali)
  -- Xt becomes X_{t}
  s({ trig = "Xt", snippetType = "autosnippet" },
    {
      t("X_{t}"),
    }
  ),
  -- Less than or equal
  s({ trig = "leq", snippetType = "autosnippet" },
    {
      t("\\leq "),
    }
  ),
  s({ trig = "geq", snippetType = "autosnippet" },
    {
      t("\\geq "),
    }
  ),
  s({ trig = "emp", snippetType = "autosnippet" },
    {
      t("\\emptyset"),
    }
  ),
  s({ trig = "cdot", snippetType = "autosnippet" },
    {
      t("\\cdot "),
    }
  ),
  s({ trig = "...", snippetType = "autosnippet" },
    {
      t("\\dots"),
    }
  ),
  s({ trig = "inf", snippetType = "autosnippet" },
    {
      t("\\inf"),
    }
  ),
  s({ trig = 'spp', snippetType = "autosnippet" },
    {
      t("\\sup"),
    }
  ),
  -- Trigonometry
  s({ trig = 'sn', snippetType = "autosnippet" },
    {
      t("\\sin"),
    }
  ),
  s({ trig = 'cs', snippetType = "autosnippet" },
    {
      t("\\cos"),
    }
  ),
  s({ trig = 'RR', snippetType = "autosnippet" },
    {
      t("\\mathbb{R}"),
    }
  ),
  s({ trig = 'RN', snippetType = "autosnippet" },
    {
      t("\\mathbb{R}^{N}"),
    }
  ),
  -- Space of continuous functions with compact support
  s({ trig = 'Cc', snippetType = "autosnippet" },
    {
      t("\\mathcal{C}_{C}(\\mathbb{R}^{N})"),
    }
  ),

  -- Limits TODO: selection option n \to \infty
  s({ trig = '([^%a])lm', regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      [[<>\displaystyle\lim_{<> \to <>}]],
      {
        f(function(_, snip) return snip.captures[1] end),
        i(1, "n"),
        i(2, "\\infty")
      }
    )
  ),
  -- Limsup and liminf
  s({ trig = '([^%a])lsup', regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      [[<>\displaystyle\limsup_{<>}]],
      {
        f(function(_, snip) return snip.captures[1] end),
        i(1),
      }
    )
  ),
  s({ trig = '([^%a])linf', regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      [[<>\displaystyle\liminf_{<>}]],
      {
        f(function(_, snip) return snip.captures[1] end),
        i(1),
      }
    )
  ),

  -- Derivatives TODO: default options
  s({ trig = '([^%a])prd', regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      [[<>\frac{\partial <>}{\partial <>}]],
      {
        f(function(_, snip) return snip.captures[1] end),
        i(1),
        i(2)
      }
    )
  ),
  s({ trig = '([^%a])pa2', regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      [[<>\frac{\partial^{2}} <>}{\partial <>}^{2}]],
      {
        f(function(_, snip) return snip.captures[1] end),
        i(1),
        i(2)
      }
    )
  ),
  s({ trig = '([^%a])pa3', regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      [[<>\frac{\partial^{3}} <>}{\partial <>}^{3}]],
      {
        f(function(_, snip) return snip.captures[1] end),
        i(1),
        i(2)
      }
    )
  ),

  -- Integrals
  s({ trig = '([^%a])dint', regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      [[<>\displaystyle\int_{<>}^{<>} \, d<>]],
      {
        f(function(_, snip) return snip.captures[1] end),
        i(1),
        i(2),
        i(3)
      }
    )
  ),
  s({ trig = '([^%a])oinf', regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      [[<>\displaystyle\int_{0}^{\infty} \, d<>]],
      {
        f(function(_, snip) return snip.captures[1] end),
        i(1),
      }
    )
  ),
  s({ trig = '([^%a])nfi', regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      [[<>\displaystyle\int_{-\infty}^{\infty} \, d<>]],
      {
        f(function(_, snip) return snip.captures[1] end),
        i(1),
      }
    )
  ),
  s({ trig = '([^%a])ints', regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta(
      [[<>\displaystyle\int_{<>} \, d<>]],
      {
        f(function(_, snip) return snip.captures[1] end),
        i(1),
        i(2),
      }
    )
  ),

  -- Parse snippets from other engines
  -- ls.parser.parse_snippet({trig = "beg", wordTrig = true, snippetType="autosnippet"}, "\\begin{$1}\n\t$2\n\\end{$1}"),
  ls.parser.parse_snippet({ trig = "tayl", wordTrig = true, snippetType = "autosnippet" },
    "${0:f}(${1:x} + ${2:h}) = ${0:f}(${1:x}) + ${0:f}'(${1:x})${2:h} + ${0:f}''(${1:x}) \\frac{${2:h}^{2}}{2!} + \\dots$3"),
  -- ls.parser.parse_snippet({ trig = "mk", name = "Math" }, "\\( ${1:${TM_SELECTED_TEXT}} \\)$0"),
  -- ls.parser.parse_snippet({trig = "", wordTrig = true, snippetType = "autosnippet"}, "")



}
