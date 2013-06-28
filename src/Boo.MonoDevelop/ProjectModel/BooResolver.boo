namespace Boo.MonoDevelop.ProjectModel

import MonoDevelop.Ide.TypeSystem

import ICSharpCode.NRefactory
import ICSharpCode.NRefactory.CSharp
import ICSharpCode.NRefactory.CSharp.Completion

class BooResolver:
	_compilationUnit as SyntaxTree

	def constructor(compilationUnit as SyntaxTree, fileName as string):
		_compilationUnit = compilationUnit
		
	def Resolve(result as CSharpCompletionEngineBase.ExpressionResult, location as TextLocation):
#		type = TypeAt(location)
#		if type is not null:
#			return MemberResolveResult(type)
		return null
		
	private def TypeAt(location as TextLocation):
		if _compilationUnit is null:
			return null
			
#		for type in _compilationUnit.Types:
#			if type.BodyRegion.Contains(location):
#				return type
		return null