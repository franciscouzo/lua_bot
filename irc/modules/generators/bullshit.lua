-- http://sourceforge.net/projects/cbsg/

local function make_eventual_plural(s, plural)
	if #s < 1 or not plural then
		return s
	elseif s == "matrix" then
		return "matrices"
	elseif s == "analysis" then
		return "analyses"
	elseif s:match("[sxzh]$") then
		return s .. "es"
	elseif s:sub(-1) == "y" then
		return s:sub(1, -2) .. "ies"
	else
		return s .. "s"
	end
end

local function build_plural_verb(verb, plural)
	if plural then
		return verb
	elseif verb:match("[osz]$") then
		return verb:sub(1, -2) .. "es"
	elseif verb:match("[cs]h$") then
		return verb .. "es"
	elseif verb:match("[cs].$") then
		return verb .. "s"
	elseif verb:match("[aeiou]y$") then
		return verb .. "s"
	elseif verb:match("[aeiou].$") then
		return verb:sub(1, -2) .. "ies"
	else
		return verb .. "s"
	end
end

local function add_indefinite_article(s, plural)
	if plural then
		return s
	elseif s:match("^[aeiou]") then
		return "an " .. s
	else
		return "a " .. s
	end
end

local function random_choice(t)
	return t[math.random(#t)]
end

local function boss()
	local r = math.random(4)

	local function department()
		return random_choice({
			"Human Resources", "Controlling", "Internal Audit", "Legal",
			"Operations", "Management Office", "Customer Relations",
			"Client Leadership", "Client Relationship", "Business Planning",
			"Business Operations", "IT Strategy", "IT Operations"
		})
	end
	local r = math.random(4)
	if r == 1 then
		local r = math.random(8)
		local managing
		if r == 1 then
			managing = "Managing "
		elseif r == 2 then
			managing = "Acting "
		else
			managing = ""
		end
		local age = math.random(4) == 1 and "Senior " or ""
		local exec = math.random(6) == 1 and "Executive" or ""
		local vice = math.random(4) == 1 and "Vice " or ""

		local title
		local r = math.random(4)
		if r == 1 then
			title = vice .. "Director"
		elseif r == 2 then
			title = "Chief"
		elseif r == 3 then
			local co = math.random(4) == 1 and "Co-" or ""
			title = co .. "Head"
		else
			title = vice .. "President"
		end
		return managing .. age .. exec .. title .. " of " .. department()
	else
		local r = 20
		local groupal
		if r == 1 then
			groupal = "Group "
		elseif r == 2 then
			groupal = "Global"
		else
			groupal = ""
		end
		local r = math.random(14)
		local department_or_top_role
		if r == 1 then
			department_or_top_role = "Visionary"
		else
			department_or_top_role = department()
		end
		return groupal .. "Chief " .. department_or_top_role .. " Officer"
	end
end

local function matrix_or_so()
	local r = math.random(10)
	if r <= 2 then
		return "organization"
	elseif r <= 5 then
		return "silo"
	elseif r <= 8 then
		return "matrix"
	elseif r == 9 then
		return "cube"
	else
		return "sphere"
	end
end

local function thing_adjective()
	return random_choice({
		"efficient", "strategic", "constructive", "proactive", "strong",
		"key", "global", "corporate", "cost-effective", "focused", "top-line",
		"credible", "agile", "holistic", "new", "adaptive", "optimal",
		"unique", "core", "compliant", "goal-oriented", "non-linear",
		"problem-solving", "prioritizing", "cultural", "future-oriented",
		"potential", "versatile", "leading", "dynamic", "progressive",
		"non-deterministic", "informed", "leveraged", "challenging",
		"intelligent", "controlled", "educated", "non-standard", "underlying",
		"centralized", "decentralized", "reliable", "consistent", "competent",
		"prospective", "collateral", "functional", "tolerably expensive",
		"organic", "forward-looking", "next-level", "executive", "seamless",
		"spectral", "balanced", "effective", "integrated", "systematized",
		"parallel", "responsive", "synchronized", "compatible",
		"carefully thought-out", "cascading", "high-level", "siloed",
		"operational", "future-ready", "flexible", "movable", "right",
		"productive", "evolutionary", "overarching", "documented", "awesome",
		"coordinated", "aligned", "enhanced", "replacement",
		"industry-standard", "accepted", "agreed-upon", "target",
		"customer-centric", "wide-spectrum", "well-communicated",
		"cutting-edge", "best-in-class", "state-of-the-art", "verifiable",
		"solid", "inspiring", "growing", "market-altering", "vertical",
		"emerging", "differentiating", "integrative", "cross-functional",
		"measurable", "well-planned", "accessible", "actionable",
		"accurate", "insightful", "relevant", "long-term", "top", "tactical",
		"best-of-breed", "robust", "targeted", "personalized", "interactive",
		"streamlined", "transparent", "traceable", "far-reaching", "powerful",
		"improved", "executive-level", "goal-based", "top-level",
		"cooperative", "value-adding", "streamlining", "time-honored",
		"idiosyncratic", "sustainable", "in-depth", "immersive",
		"cross-industry", "time-phased", "day-to-day", "present-day",
		"medium-to-long-term", "profit-maximizing", "generic", "granular",
		"market-driven", "value-driven", "well-defined", "outward-looking",
		"scalable", "strategy-focused", "promising", "collaborative",
		"scenario-based", "principle-based", "vision-setting",
		"client-oriented", "long-established", "established",
		"organizational", "visionary", "trusted", "full-scale", "firm-wide",
		"fast-growth", "performance-based", "high-performing", "top-down",
		"cross-enterprise", "outsourced", "situational", "bottom-up",
		"multidisciplinary", "one-to-one", "goal-directed",
		"intra-organisational", "high-performing", "multi-source",
		"360-degree", "motivational", "differentiated", "solutions-based",
		"compelling", "structural", "go-to-market", "on-message", "adequate",
		"value-enhancing", "mission-critical", "business enabling",
		"transitional", "future", "game-changing", "enterprise-wide",
		"rock-solid", "bullet-proof", "superior", "genuine", "alert",
		"nimble", "phased", "selective", "macroscopic", "low-risk high-yield",
		"interconnected", "high-margin"
	})
end

local function timeless_event()
	return random_choice({
		"kick-off", "roll-out", "client event", "quarter results"
	})
end

local function growth()
	superlative = random_choice({
		"organic", "double-digit", "upper single-digit", "breakout",
		"unprecedented", "unparallelled", "proven", "measured"
	})
	improvement = random_choice({
		"growth", "improvement", "throughput increase", "efficiency gain",
		"yield enhancement"
	})
	return superlative .. " " .. improvement;
end

local function thing_atom(plural)
	local function inner()
		local r = math.random(170)
		if r == 1 then
			return matrix_or_so()
		else
			return random_choice({
				"mission", "vision", "guideline", "roadmap", "timeline",
				"win-win solution", "baseline starting point", "sign-off",
				"escalation", "system", "Management Information System",
				"Quality Management System", "planning", "target", "calibration",
				"Control Information System", "process", "talent", "execution",
				"leadership", "performance", "solution provider", "value",
				"value creation", "feedback", "document","bottom line", "momentum",
				"opportunity", "credibility", "issue", "core meeting", "platform",
				"niche", "content", "communication", "goal", "skill", "alternative",
				"culture", "requirement", "potential", "challenge", "empowerment",
				"benchmarking", "framework", "benchmark", "implication",
				"integration", "enabler", "control", "trend", "business case",
				"architecture", "action plan", "project", "review cycle",
				"trigger event", "strategy formulation", "decision",
				"enhanced data capture", "energy", "plan", "initiative", "priority",
				"synergy", "incentive", "dialogue", "concept", "time-phase",
				"projection", "blended approach", "low hanging fruit",
				"forward planning", "pre-plan", "pipeline", "bandwidth", "workshop",
				"paradigm", "paradigm shift", "strategic staircase", "cornerstone",
				"executive talent", "evolution", "workflow", "message",
				"risk/return profile", "efficient frontier", "pillar",
				"internal client", "consistency", "on-boarding process",
				"dotted line", "action item", "cost efficiency", "channel",
				"convergence", "infrastructure", "metric", "technology",
				"relationship", "partnership", "supply-chain", "portal", "solution",
				"business line", "white paper", "scalability", "innovation",
				"Strategic Management System", "Balanced Scorecard", "differentiator",
				"case study", "idiosyncrasy", "benefit", "say/do ratio",
				"segmentation", "image", "realignment", "business model",
				"business philosophy", "branding", "methodology", "profile",
				"measure", "measurement", "philosophy", "branding strategy",
				"efficiency", "industry", "commitment", "perspective",
				"risk appetite", "best practice", "brand identity",
				"customer centricity", "shareholder value", "attitude", "mindset",
				"flexibility", "granularity", "engagement", "pyramid", "market",
				"diversity", "interdependency", "scaling", "asset", "flow charting",
				"value proposition", "performance culture", "change", "reward",
				"learning", "next step", "delivery framework", "structure",
				"support structure", "standardization", "objective", "footprint",
				"transformation process", "policy", "sales target", "ecosystem",
				"market practice", "atmosphere", "operating strategy",
				"core competency"
			})
		end
	end

	if not plural then
		local r = math.random(200)
		if r <= 77 then
			return random_choice({
				"team building", "focus", "strategy",
				"planning granularity", "core business", "implementation",
				"intelligence", "governance", "ROE", "EBITDA",
				"enterprise content management", "excellence", "trust",
				"respect", "openness", "transparency", "Quality Research",
				"decision making", "risk management",
				"enterprise risk management", "leverage", "diversification",
				"successful execution", "effective execution", "selectivity",
				"optionality", "expertise", "awareness", "broader thinking",
				"client focus", "thought leadership", "quest for quality",
				"360-degree thinking", "drill-down", "impetus", "fairness",
				"intellect", "emotional impact", "emotional intelligence",
				"adaptability", "stress management", "self-awareness",
				"strategic thinking", "cross fertilization", "effectiveness",
				"customer experience", "centerpiece", "SWOT analysis",
				"responsibility", "accountability", "ROI", "line of business",
				"serviceability", "responsiveness", "simplicity",
				"portfolio shaping", "knowledge sharing", "continuity",
				"visual thinking", "interoperability", "compliance",
				"teamwork", "self-efficacy", "decision-making",
				"line-of-sight", "scoping", "line-up", "predictability",
				"recognition", "investor confidence", "competitive advantage",
				"uniformity", "competitiveness", "big picture",
				"resourcefulness", "quality", "upside focus"
			})
		elseif r == 78 then
			return timeless_event()
		else
			return inner()
		end
	else
		local r = math.random(200)
		if r <= 12 then
			return random_choice({
				"key target markets", "style guidelines",
				"key performance indicators", "market conditions",
				"market forces", "market opportunities", "tactics",
				"organizing principles", "interpersonal skills",
				"roles and responsibilities", "cost savings",
				"lessons learned"
			})
		else
			return make_eventual_plural(inner(), True)
		end
	end
end

local function person(plural)
	if not plural then
		local r = math.random(17)
		if r <= 11 then
			return random_choice({"steering committee", "group", "project manager",
				"community", "sales manager", "enabler", "powerful champion",
				"thought leader", "gatekeeper", "resource",
				"senior support staff"
			})
		elseif r == 12 then
			return thing_atom(math.random(2) == 1) .. " champion"
		else
			return boss()
		end
	else
		return random_choice({
			"key people", "human resources", "customers", "clients",
			"resources", "team players", "enablers", "stakeholders",
			"standard-setters", "partners", "business leaders"
		})
	end
end

local function thing(plural)
	local r = math.random(110)
	if r <= 10 then
		return thing_adjective() .. ", " .. thing_adjective() .. " " .. thing_atom(plural)
	elseif r <= 15 then
		return thing_adjective() .. " and " .. thing_adjective() .. " " .. thing_atom(plural)
	elseif r <= 71 then
		return thing_adjective() .. " " .. thing_atom(plural)
	elseif r <= 73 then
		return thing_adjective() .. " and/or " .. thing_adjective() .. " " .. thing_atom(plural)
	elseif r <= 75 then
		return growth()
	elseif r <= 80 then
		return thing_adjective() .. ", " .. thing_adjective() .. " and " .. thing_adjective() .. " " .. thing_atom(plural)
	elseif r <= 85 then
		return thing_adjective() .. ", " .. thing_adjective() .. ", " .. thing_adjective() .. " and " .. thing_adjective() .. " " .. thing_atom(plural)
	else
		return thing_atom(plural)
	end
end

local function bad_things()
	return random_choice({
		"issues", "intricacies", "organizational diseconomies", "black swans",
		"gaps", "inefficiencies", "overlaps", "known unknowns",
		"unknown unknowns", "soft cycle issues", "obstacles", "surprises",
		"weaknesses", "threats", "barriers to success", "barriers",
		"shortcomings", "problems", "uncertainties"
	})
end

local function eventual_adverb()
	local r = math.random(4)
	if r == 1 then
		return random_choice({
			"interactively", "credibly", "quickly", "proactively", "200%",
			"24/7", "globally", "culturally", "technically", "strategically",
			"swiftly", "cautiously", "expediently", "organically",
			"carefully", "significantly", "conservatively","adequately",
			"genuinely"
		}) .. " "
	else
		return ""
	end
end

local function add_random_article(s, plural)
	local r = math.random(15)
	if r <= 2 then
		return "the " .. s
	elseif r <= 6 then
		return "our " .. s
	else
		return add_indefinite_article(s, plural)
	end
end

local function eventual_postfixed_adverb()
	local plural = math.random(2) == 1
	local r = math.random(140)
	if r <= 15 then
		return random_choice({
			" going forward", " within the industry", " across the board",
			" in this space", " from the get-go", " at the end of the day",
			" throughout the organization", " as part of the plan",
			" by thinking outside of the box", " ahead of schedule",
			", relative to our peers", " on a transitional basis",
			" by expanding boundaries", " by nurturing talent",
			", as a Tier 1 company"
		})
	elseif r == 16 then
		return " using " .. add_random_article(thing(plural), plural)
	elseif r == 17 then
		return " by leveraging " .. add_random_article(thing(plural), plural)
	elseif r == 18 then
		return " taking advantage of " .. add_random_article(thing(plural), plural)
	elseif r == 19 then
		return " within the " .. matrix_or_so()
	elseif r == 20 then
		return " across the " .. make_eventual_plural(matrix_or_so(), plural)
	elseif r == 21 then
		return " up-front"
	elseif r == 22 then
		 return " resulting in " .. growth()
	elseif r == 23 then
		return " reaped from our " .. growth()
	elseif r == 24 then
		return " as a consequence of " .. growth()
	elseif r == 25 then
		return " because " .. add_random_article(thing(plural), plural) .. " " .. build_plural_verb("produce", plural) .. " " .. growth()
	else
		return ""
	end
end

local function person_verb_having_thing_complement(plural)
	local inner = random_choice({
		"manage", "target", "streamline", "improve", "optimize", "achieve",
		"secure", "address", "boost", "deploy", "innovate", "right-scale",
		"formulate", "transition", "leverage", "focus on", "synergize",
		"generate", "analyse", "integrate", "empower", "benchmark", "learn",
		"adapt", "enable", "strategize", "prioritize", "pre-prepare",
		"deliver", "champion", "embrace", "enhance", "engineer", "envision",
		"incentivize", "maximize", "visualize", "whiteboard",
		"institutionalize", "promote", "overdeliver", "right-size",
		"rebalance", "re-imagine", "influence", "facilitate", "drive",
		"structure", "standardize", "accelerate", "deepen", "strengthen",
		"broaden", "enforce", "establish", "foster", "build", "differentiate",
		"take a bite out of", "table", "flesh out", "reach out"
	})
	return build_plural_verb(inner, plural)
end

local function person_verb_having_bad_thing_complement(plural)
	local inner = random_choice({"address", "identify", "avoid", "mitigate"})
	return build_plural_verb(inner, plural)
end

local function thing_verb_having_thing_complement(plural)
	local inner = random_choice({
		"streamline", "interact with", "boost", "generate", "impact",
		"enhance", "leverage", "synergize", "generate", "empower", "enable",
		"prioritize", "transfer", "drive", "result in", "promote",
		"influence", "facilitate", "aggregate", "architect", "cultivate",
		"engage", "structure", "standardize", "accelerate", "deepen",
		"strengthen", "enforce", "foster"
	})
	return build_plural_verb(inner, plural)
end

local function thing_verb_having_person_complement(plural)
	local inner = random_choice({
		"motivate", "target", "enable", "drive", "synergize", "empower",
		"prioritize", "incentivise", "inspire", "transfer", "promote",
		"influence", "strengthen"
	})
	return build_plural_verb(inner, plural)
end

local function person_verb_and_complement(plural)
	local inner = random_choice({
		"streamline the process", "address the overarching issues",
		"benchmark the portfolio", "manage the cycle",
		"figure out where we come from, where we are going to",
		"maximize the value", "execute the strategy", "think out of the box",
		"think differently", "manage the balance", "loop back", "conversate",
		"go forward together", "achieve efficiencies", "deliver",
		"stay in the mix", "stay in the zone", "evolve",
		"exceed expectations", "develop the plan",
		"develop the blue print for execution", "grow and diversify",
		"fuel changes", "nurture talent", "turn every stone",
		"challenge established ideas", "manage the portfolio",
		"align resources", "drive the business forward", "make things happen",
		"stay ahead", "outperform peers", "surge ahead",
		"manage the downside", "stay in the wings", "come to a landing",
		"shoot it over", "move the needle", "connect the dots",
		"connect the dots to the end game", "reset the benchmark",
		"take it offline", "peel the onion", "drill down"
	})
	return build_plural_verb(inner, plural)
end

local function thing_verb_and_ending(plural)
	local compl_sp = math.random(2) == 1
	local r = math.random(101)
	if r <= 55 then
		return thing_verb_having_thing_complement(plural) .. " " .. add_random_article(thing(compl_sp), compl_sp)
	elseif r <= 100 then
		return thing_verb_having_person_complement(plural) .. " the " .. person(compl_sp)
	else
		return build_plural_verb("add", plural) .. " value"
	end
end

local function person_verb_and_ending(plural)
	local compl_sp = math.random(2) == 1
	local r = math.random(95)
	if r <= 10 then
		return person_verb_and_complement(plural)
	elseif r <= 15 then
		return person_verb_having_bad_thing_complement(plural) .. " " .. add_random_article(bad_things(), plural)
	else
		return person_verb_having_thing_complement(plural) .. " " .. add_random_article(thing(compl_sp), compl_sp)
	end
end

local function faukon()
	local r = math.random(6)
	if r <= 5 then
		return random_choice({
			"we need to", "we've got to", "the reporting unit should",
			"controlling should", "pursuing this route will enable us to"
		})
	else
		return "we must activate the " .. matrix_or_so() .. " to"
	end
end

local function proposition()
	local plural = math.random(2) == 1
	local r = math.random(100)
	if r <= 5 then
		return faukon() .. " " .. eventual_adverb() .. person_verb_and_ending(True) .. eventual_postfixed_adverb()
	elseif r <= 50 then
		return "the " .. person(plural) .. " " .. eventual_adverb() .. person_verb_and_ending(plural) .. eventual_postfixed_adverb()
	else
		return add_random_article(thing(plural), plural) .. " " .. eventual_adverb() .. thing_verb_and_ending(plural) .. eventual_postfixed_adverb()
	end
end

local function articulated_propositions()
	local r = math.random(28)
	if r <= 17 then
		return proposition()
	elseif r <= 18 then
		return proposition() .. "; this is why " .. proposition()
	elseif r <= 19 then
		return proposition() .. "; nevertheless " .. proposition()
	elseif r <= 20 then
		return proposition() .. ", whereas " .. proposition()
	elseif r <= 21 then
		return "our gut-feeling is that " .. proposition()
	elseif r <= 22 then
		return proposition() .. ". In the same time, " .. proposition()
	elseif r <= 23 then
		return proposition() .. ". As a result, " .. proposition()
	elseif r <= 24 then
		return proposition() .. ", whilst " .. proposition()
	else
		return proposition() .. ", while " .. proposition()
	end
end

local function capitalize(s)
	local out = {}
	for sentence in s:gmatch("[^%.]+") do
		out[#out + 1] = sentence:gsub("^%s*.", string.upper)
	end
	return table.concat(out)
end
local function sentence()
	return capitalize(articulated_propositions()) .. "."
end

local function sentence_guaranteed_amount(count)
	local sentences = {}
	for i = 1, count do
		sentences[i] = sentence()
	end
	return table.concat(sentences, " ")
end

return function(irc, state, channel, n)
	return sentence_guaranteed_amount(math.max(1, math.min(5, n or math.random(2, 3))))
end