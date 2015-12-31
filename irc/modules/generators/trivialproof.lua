local utils = require("irc.utils")

-- https://github.com/alangpierce/TheProofIsTrivial

local intros = {
	"Just biject it to a",
	"Just view the problem as a"
}

local adjectives = {
	"abelian",
	"associative",
	"computable",
	"Lebesgue-measurable",
	"semi-decidable",
	"simple",
	"combinatorial",
	"structure-preserving",
	"diagonalizable",
	"nonsingular",
	"orientable",
	"twice-differentiable",
	"thrice-differentiable",
	"countable",
	"prime",
	"complete",
	"continuous",
	"trivial",
	"3-connected",
	"bipartite",
	"planar",
	"finite",
	"nondeterministic",
	"alternating",
	"convex",
	"undecidable",
	"dihedral",
	"context-free",
	"rational",
	"regular",
	"Noetherian",
	"Cauchy",
	"open",
	"closed",
	"compact",
	"clopen",
	"pointless"
}

local set_nouns = {
	{"multiset"},
	{"metric space"},
	{"group"},
	{"monoid"},
	{"semigroup"},
	{"ring"},
	{"field"},
	{"module"},
	{"topological space"},
	{"Hilbert space"},
	{"manifold"},
	{"hypergraph"},
	{"DAG"},
	{"residue class"},
	{"logistic system"},
	{"complexity class"},
	{"language"},
	{"poset"},
	{"algebra"},
	{"Lie algebra"},
	{"Dynkin system"},
	{"sigma-algebra"},
	{"ultrafilter"}
}

local all_nouns = {
	{"integer"},
	{"Turing machine"},
	{"automorphism"},
	{"bijection"},
	{"generating function"},
	{"taylor series", "taylor series"},
	{"linear transformation"},
	{"pushdown automaton", "pushdown automata"},
	{"combinatorial game"},
	{"equivalence relation"},
	{"tournament"},
	{"random variable"},
	{"triangulation"},
	{"unbounded-fan-in circuit"},
	{"log-space reduction"},
	{"Markov chain"},
	{"4-form"},
	{"7-chain"}
}

for _, noun in ipairs(set_nouns) do
	table.insert(all_nouns, noun)
end

function plural(noun_with_override)
	if noun_with_override[2] then
		return nounWithOverride[2]
	else
		local text = noun_with_override[1]
		if text:sub(-1) == "s" then
			return text .. "es"
		else
			return text .. "s"
		end
	end
end

return function(irc, state, channel)
	local intro = utils.random_choice(intros)
	local adjective = utils.random_choice(adjectives)

	local intro = intro .. (adjective:match("^[aeiou]") and "n" or "")
	
	local text = ("The proof is trivial! %s %s %s whose elements are %s %s."):format(
		intro,
		adjective,
		utils.random_choice(set_nouns)[1],
		utils.random_choice(adjectives),
		plural(utils.random_choice(all_nouns))
	)

	return text
end