namespace UnityScript.MonoDevelop.Completion

import System.Linq
import MonoDevelop.Ide.Gui
import MonoDevelop.Ide.CodeCompletion
import ICSharpCode.NRefactory.Completion
import ICSharpCode.NRefactory.CSharp.Completion
import Boo.Ide

class UnityScriptParameterDataProvider(ParameterDataProvider):
	_methods as List of MethodDescriptor
	_document as Document
	
	def constructor(document as Document, methods as List of MethodDescriptor):
		_methods = methods
		_document = document
		
	Count:
		get: return _methods.Count

	def GetCurrentParameterIndex(widget as ICompletionWidget, context as CodeCompletionContext):
		line = _document.Editor.GetLineText(context.TriggerLine)
		offset = _document.Editor.Caret.Column-2
		if(0 <= offset and offset < line.Length):
			stack = 0
			for i in range(offset, -1, -1):
				current = line[i:i+1]
				if (')' == current): --stack
				elif('(' == current): ++stack
			if (1 == stack):
				return /,/.Split(line[0:offset+1]).Length
		return -1

	def GetHeading (overloadIndex as int, parameterMarkup as (string), currentParameterIndex as int):
		return GetMethodMarkup (overloadIndex, parameterMarkup, currentParameterIndex)
		
	def GetMethodMarkup(overloadIndex as int, parameterMarkup as (string), currentParameterIndex as int):
		method = _methods[overloadIndex]
		methodName = System.Security.SecurityElement.Escape(method.Name)
		methodReturnType = System.Security.SecurityElement.Escape(method.ReturnType)
		return "${methodName}(${string.Join(',',parameterMarkup)}): ${methodReturnType}"

	def GetParameterName (overloadIndex as int, parameterIndex as int):
		return GetParameterMarkup (overloadIndex, parameterIndex)
				
	def GetParameterDescription (overloadIndex as int, parameterIndex as int):
		return GetParameterMarkup (overloadIndex, parameterIndex)
	
	def GetDescription (overloadIndex as int, parameterIndex as int):
		return GetParameterMarkup (overloadIndex, parameterIndex)
		
	def GetParameterMarkup(overloadIndex as int, parameterIndex as int):
		return Enumerable.ElementAt(_methods[overloadIndex].Arguments, parameterIndex).Replace (" as ", ": ")
		
	def GetParameterCount(overloadIndex as int):
		return Enumerable.Count(_methods[overloadIndex].Arguments)
		
	def AllowParameterList (overloadIndex as int):
		return true
		
	override def CreateTooltipInformation (overloadIndex as int, parameterIndex as int, smartWrap as bool) as TooltipInformation:
		info = TooltipInformation ()
		parameterMarkup = System.Collections.Generic.List of string ()
		for i in range(0, GetParameterCount (overloadIndex), 1):
			parameterMarkup.Add (GetParameterMarkup (overloadIndex, i))
		info.SignatureMarkup = GetMethodMarkup (overloadIndex, parameterMarkup.ToArray (), parameterIndex)
		return info

