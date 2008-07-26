namespace Boo.OMeta

import Boo.Adt
import System.Collections.Specialized

let EndOfInput = EndOfInputFailure()

data OMetaFailure() = \
		EndOfInputFailure() \
		| PredicateFailure(Predicate as string) \
		| NegationFailure(Predicate as string) \
		| LeftRecursionFailure() \
		| ExpectedValueFailure(Expected as object) \
		| ObjectPatternFailure(Pattern as string) \
		| ChoiceFailure(Failures as Boo.Lang.List[of FailedMatch]) \
		| RuleFailure(Rule as string, Reason as OMetaFailure)

data OMetaMatch(Input as OMetaInput) = \
		SuccessfulMatch(Value as object) \
		| FailedMatch(Failure as OMetaFailure) \
		| LR(@detected as bool) // internal use only

callable OMetaRule(context as OMetaGrammar, input as OMetaInput) as OMetaMatch

interface OMetaGrammar:
	
	def InstallRule(ruleName as string, rule as OMetaRule)
	def Apply(context as OMetaGrammar, rule as string, input as OMetaInput) as OMetaMatch
	def SuperApply(context as OMetaGrammar, rule as string, input as OMetaInput) as OMetaMatch

class OMetaGrammarRoot(OMetaGrammar):
	
	class MemoKey:
		final _rule as string
		final _input as OMetaInput
		
		def constructor(rule as string, input as OMetaInput):
			_rule = rule
			_input = input
			
		override def Equals(o):
			other as MemoKey = o
			return _input is other._input and _rule is other._rule
			
		override def GetHashCode():
			return _rule.GetHashCode() ^ _input.GetHashCode()
			
		override def ToString():
			return "MemoKey(${_rule}, ${_input})"
	
	_rules = ListDictionary()
	_memo = HybridDictionary()
	
	def InstallRule(ruleName as string, rule as OMetaRule):
		_rules[ruleName] = rule
	
	def Apply(context as OMetaGrammar, rule as string, input as OMetaInput):
		
		memoKey = MemoKey(rule, input)
		m = _memo[memoKey]
		if m is null:
			lr = LR(input, false)
			_memo[memoKey] = lr
			m = Eval(context, rule, input)
			_memo[memoKey] = m
			if lr.detected and m isa SuccessfulMatch:
				return GrowLR(context, rule, input, m, memoKey)
			else:
				return m
		else:
			lr = m as LR
			if lr is not null:
				lr.detected = true
				return FailedMatch(input, LeftRecursionFailure())
			else:
				return m
		
	def GrowLR(context as OMetaGrammar, rule as string, input as OMetaInput, lastSuccessfulMatch as OMetaMatch, memoKey as MemoKey):
		while true:
			m = Eval(context, rule, input)
			if m isa FailedMatch or m.Input.Position <= lastSuccessfulMatch.Input.Position:
				break
			_memo[memoKey] = lastSuccessfulMatch = m
		return lastSuccessfulMatch
		
	def Eval(context as OMetaGrammar, rule as string, input as OMetaInput):
		found as OMetaRule = _rules[rule]
		if found is not null:
			return found(context, input)
		return RuleMissing(context, rule, input)
		
	def SuperApply(context as OMetaGrammar, rule as string, input as OMetaInput):
		return Apply(context, rule, input)
		
	virtual def RuleMissing(context as OMetaGrammar, rule as string, input as OMetaInput) as OMetaMatch:
		raise "Rule '${rule}' missing!"
		
class OMetaGrammarPrototype(OMetaGrammarRoot):
	
	def constructor():
		SetUpRule "whitespace", "char.IsWhitespace", char.IsWhiteSpace
		SetUpRule "letter", "char.IsLetter", char.IsLetter
		SetUpRule "digit", "char.IsDigit", char.IsDigit
		SetUpRule "_", "_", { o | return true }
		
	private def SetUpRule(name as string, predicateDescription as string, predicate as System.Predicate[of object]):
		InstallRule(name, makeRule(name, predicateDescription, predicate))
		
class OMetaDelegatingGrammar(OMetaGrammarRoot):
	
	_prototype as OMetaGrammar
	
	def constructor(prototype as OMetaGrammar):
		_prototype = prototype
		
	override def RuleMissing(context as OMetaGrammar, rule as string, input as OMetaInput):
		return _prototype.Apply(context, rule, input)
		
	override def SuperApply(context as OMetaGrammar, rule as string, input as OMetaInput):
		return _prototype.Apply(context, rule, input)
		
def makeRule(ruleName as string, predicateDescription as string, predicate as System.Predicate[of object]) as OMetaRule:
	predicateFailure = PredicateFailure(predicateDescription)
	def rule(context as OMetaGrammar, input as OMetaInput) as OMetaMatch:
		if input.IsEmpty:
			return FailedMatch(input, RuleFailure(ruleName, EndOfInput))
		if  not predicate(input.Head):
			return FailedMatch(input, RuleFailure(ruleName, predicateFailure))
		return SuccessfulMatch(input.Tail, input.Head)
	return rule
