namespace UnityScript.MonoDevelop.Completion

import System
import Mono.TextEditor.Highlighting
import MonoDevelop.Core
import MonoDevelop.Ide.Gui
import MonoDevelop.Ide.CodeCompletion

import Boo.Lang.PatternMatching

import Boo.Ide
import Boo.MonoDevelop.Util.Completion

class UnityScriptEditorCompletion(BooCompletionTextEditorExtension):

	# Match "blah = new [...]" pattern
	static NEW_PATTERN = /\bnew\s+(?<namespace>[\w\d]+(\.[\w\d]+)*)?\.?/
	
	# Match "var blah: [...]" pattern
	static COLON_PATTERN = /\w\s*:\s*(?<namespace>[\w\d]+(\.[\w\d]+)*)?\.?/
	
	# Patterns that result in us doing a type completion
	static TYPE_PATTERNS = (NEW_PATTERN, COLON_PATTERN)
	
	# Patterns that result in us doing a namespace completion
	static NAMESPACE_PATTERNS = (IMPORTS_PATTERN,)
	
	# Delimiters that indicate a literal
	static LITERAL_DELIMITERS = ['"']
	
	# Scraped from UnityScript.g
	private static KEYWORDS = (
		"as",
		"break",
		"catch",
		"class",
		"continue",
		"else",
		"enum",
		"extends",
		"false",
		"final",
		"finally",
		"for",
		"function",
		"get",
		"if",
		"import",
		"implements",
		"in",
		"interface",
		"instanceof",
		"new",
		"null",
		"return",
		"public",
		"protected",
		"internal",
		"override",
		"partial",
		"pragma",
		"private",
		"set",
		"static",
		"super",
		"this",
		"throw",
		"true",
		"try",
		"typeof",
		"var",
		"virtual",
		"while",
		"yield",  
		"switch",
		"case",
		"default"
	)
	
	# Scraped from Types.cs
	private static PRIMITIVES = (   
		"byte",
		"sbyte",
		"short",
		"ushort",
		"int",
		"uint",
		"long",
		"ulong",
		"float",
		"double",
		"decimal",
		"void",
		"string",
		"object"
	)
	
	override Keywords:
		get: return KEYWORDS
		
	override Primitives:
		get: return PRIMITIVES
	
	override def Initialize():
		InstallUnityScriptSyntaxModeIfNeeded()
		super()
		
	def InstallUnityScriptSyntaxModeIfNeeded():
		doc = Document.Editor.Document
		mimeType = UnityScript.MonoDevelop.ProjectModel.UnityScriptParser.MimeType
		syntaxMode = doc.SyntaxMode as SyntaxMode
		return if syntaxMode != null and syntaxMode.MimeType == mimeType
		
		mode = Mono.TextEditor.Highlighting.SyntaxModeService.GetSyntaxMode (doc, mimeType)
		if mode is not null:
			doc.SyntaxMode = mode
		else:
			LoggingService.LogWarning(GetType() + " could not get SyntaxMode for mimetype '" + mimeType + "'.")
	
#	override def HandleCodeCompletion(context as CodeCompletionContext, completionChar as char):
#		triggerWordLength = 0
#		HandleCodeCompletion(context, completionChar, triggerWordLength)
	
	override def HandleCodeCompletion(context as CodeCompletionContext, completionChar as char, ref triggerWordLength as int):
		# print "HandleCodeCompletion(${context.ToString()}, '${completionChar.ToString()}')"
		line = GetLineText(context.TriggerLine)
		tokenLineOffset = context.TriggerLineOffset-1

		if (IsInsideComment(line, tokenLineOffset) or \
		    IsInsideLiteral(line, tokenLineOffset)):
			return null
		
		match completionChar.ToString():
			case " ":
				if (null != (completions = CompleteNamespacePatterns(context))):
					return completions
				return CompleteTypePatterns(context)
			case ":":
				return CompleteTypePatterns(context)
			case ".":
				if (null != (completions = CompleteNamespacePatterns(context))):
					return completions
				elif (null != (completions = CompleteTypePatterns(context))):
					return completions
				return CompleteMembers(context)
			otherwise:
				if(CanStartIdentifier(completionChar)):
					if(StartsIdentifier(line, tokenLineOffset)):
						# Necessary for completion window to take first identifier character into account
						--context.TriggerOffset 
						triggerWordLength = 1
						return CompleteVisible(context)
					else:
						dotLineOffset = tokenLineOffset-1
						if(0 <= dotLineOffset and line.Length > dotLineOffset and "."[0] == line[dotLineOffset]):
							--context.TriggerOffset
							triggerWordLength = 1
							return CompleteMembers(context)
		return null
		
	def CompleteNamespacePatterns(context as CodeCompletionContext):
		completions as CompletionDataList = null
		
		for pattern in NAMESPACE_PATTERNS:
			return completions if (null != (completions = CompleteNamespacesForPattern(context, pattern, "namespace")))
		return null
		
	def CompleteTypePatterns(context as CodeCompletionContext):
		completions as CompletionDataList
		for pattern in TYPE_PATTERNS:
			if (null != (completions = CompleteNamespacesForPattern(context, pattern, "namespace"))):
				completions.AddRange(CompletionData(p, Stock.Literal) for p in Primitives)
				return completions
		return null
			
	override def ShouldEnableCompletionFor(fileName as string):
		return UnityScript.MonoDevelop.IsUnityScriptFile(fileName)
		
	def IsInsideLiteral(line as string, offset as int):
		fragment = line[0:offset+1]
		for delimiter in LITERAL_DELIMITERS:
			list = List[of string]()
			list.Add(delimiter)
			if(0 == fragment.Split(list.ToArray(), StringSplitOptions.None).Length%2):
				return true
		return false
	
	override SelfReference:
		get: return "this"
		
	override EndStatement:
		get: return ";"
	
	override def GetParameterDataProviderFor(methods as List of MethodDescriptor):
		return UnityScriptParameterDataProvider(Document, methods)
