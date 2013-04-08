namespace Boo.MonoDevelop.ProjectModel


import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

import MonoDevelop.Ide.TypeSystem

import ICSharpCode.NRefactory
import ICSharpCode.NRefactory.CSharp
import ICSharpCode.NRefactory.TypeSystem
import ICSharpCode.NRefactory.TypeSystem.Implementation

class DomConversionVisitor(DepthFirstVisitor):
	
	_result as SyntaxTree
	_currentType as IType
	_namespace as string
	
	def constructor(result as SyntaxTree):
		_result = result
		
	override def OnModule(node as Module):
		_namespace = null
		Visit(node.Namespace)
		Visit(node.Members)
		
#	override def OnNamespaceDeclaration(node as Ast.NamespaceDeclaration):
#		_namespace = node.Name
#		region = BodyRegionOf(node.ParentNode)
#		domUsing = DomUsing(IsFromNamespace: true, Region: region)
#		domUsing.Add(_namespace)
#		_result.Add(domUsing)
		
#	override def OnImport(node as Import):
#		region = BodyRegionOf(node)
#		domUsing = DomUsing(Region: region)
#		domUsing.Add(node.Namespace)
#		_result.Add(domUsing)
		
#	override def OnClassDefinition(node as ClassDefinition):
#		OnTypeDefinition(node, ClassType.Class)
#		
#	override def OnInterfaceDefinition(node as InterfaceDefinition):
#		OnTypeDefinition(node, ClassType.Interface)
#		
#	override def OnStructDefinition(node as StructDefinition):
#		OnTypeDefinition(node, ClassType.Struct)
#		
#	override def OnEnumDefinition(node as EnumDefinition):
#		OnTypeDefinition(node, ClassType.Enum)
#		
#	def OnTypeDefinition(node as TypeDefinition, classType as ClassType):
#		converted = DomType(
#						Name: node.Name,
#						ClassType: classType,
#						Location: LocationOf(node),
#						BodyRegion: BodyRegionOf(node),
#						DeclaringType: _currentType,
#						Modifiers: ModifiersFrom(node))
#		
#		WithCurrentType converted:
#			Visit(node.Members)
#					
#		AddType(converted)
		
#	override def OnCallableDefinition(node as CallableDefinition):
#		parameters = System.Collections.Generic.List[of IParameter]()
#		for p in node.Parameters: parameters.Add(ParameterFrom(null, p))
#		
#		converted = DomType.CreateDelegate(_result, node.Name, LocationOf(node), ReturnTypeFrom(node.ReturnType), parameters)
#		converted.Modifiers = ModifiersFrom(node)
#		converted.DeclaringType = _currentType
#		converted.BodyRegion = BodyRegionOf(node)
#		
#		for p in parameters: p.DeclaringMember = converted
#		
#		AddType(converted)
		
#	override def OnField(node as Field):
#		if _currentType is null: return
#		
#		_currentType.Add(DomField(
#							Name: node.Name,
#							ReturnType: ParameterTypeFrom(node.Type),
#							Location: LocationOf(node),
#							BodyRegion: BodyRegionOf(node),
#							DeclaringType: _currentType,
#							Modifiers: ModifiersFrom(node)))
							
#	override def OnProperty(node as Property):
#		if _currentType is null: return
#		
#		try:
#			converted = DomProperty(
#								Name: node.Name,
#								ReturnType: ParameterTypeFrom(node.Type),
#								Location: LocationOf(node),
#								BodyRegion: BodyRegionOf(node),
#								DeclaringType: _currentType)
#			if node.Getter is not null:
#				converted.PropertyModifier |= PropertyModifier.HasGet
#				converted.GetterModifier = ModifiersFrom(node.Getter)
#				converted.GetRegion = BodyRegionOf(node.Getter)
#			if node.Setter is not null:
#				converted.PropertyModifier |= PropertyModifier.HasSet
#				converted.SetterModifier = ModifiersFrom(node.Setter)
#				converted.SetRegion = BodyRegionOf(node.Setter)
#								
#			_currentType.Add(converted)
#		except x:
#			print x, x.InnerException
#			
#	override def OnEvent(node as Event):
#		if _currentType is null: return
#		
#		converted = DomEvent(
#							Name: node.Name,
#							ReturnType: ParameterTypeFrom(node.Type),
#							Location: LocationOf(node),
#							BodyRegion: BodyRegionOf(node),
#							DeclaringType: _currentType)
#		_currentType.Add(converted)
#							
#	override def OnEnumMember(node as EnumMember):
#		if _currentType is null: return
#		
#		_currentType.Add(DomField(
#							Name: node.Name,
#							ReturnType: DomReturnType(_currentType),
#							Location: LocationOf(node),
#							DeclaringType: _currentType,
#							Modifiers: Modifiers.Public | Modifiers.Static | Modifiers.Final))
							
	override def OnConstructor(node as Constructor):
		OnMethodImpl(node) #, MethodModifier.IsConstructor)
		
	override def OnDestructor(node as Destructor):
		OnMethodImpl(node) #, MethodModifier.IsFinalizer)
		
	override def OnMethod(node as Method):
		OnMethodImpl(node) #, MethodModifier.None)
		
	def OnMethodImpl(node as Method): #, methodModifier as MethodModifier):
		pass
#		if _currentType is null: return
#		
#		converted = DefaultUnresolvedMethod(_currentType, node.Name)
#							
##							Location: LocationOf(node),
##							BodyRegion: BodyRegionOf(node),
##							DeclaringType: _currentType,
##							ReturnType: (MethodReturnTypeFrom(node) if IsRegularMethod(methodModifier) else null),
##							Modifiers: ModifiersFrom(node))
#							# MethodModifier: methodModifier)
#							
##		for parameter in node.Parameters:
##			converted.Add(ParameterFrom(converted, parameter))
#		
#		_currentType.Add(converted)
		
#	def IsRegularMethod(modifier as MethodModifier):
#		return true
#		match modifier:
#			case MethodModifier.IsConstructor | MethodModifier.IsFinalizer:
#				return false
#			otherwise:
#				return true
		
	def ModifiersFrom(node as TypeMember):
		modifiers = Modifiers.None
		modifiers |= Modifiers.Public if node.IsPublic
		modifiers |= Modifiers.Private if node.IsPrivate
		modifiers |= Modifiers.Protected if node.IsProtected
		modifiers |= Modifiers.Internal if node.IsInternal
		modifiers |= Modifiers.Static if node.IsStatic
		modifiers |= Modifiers.Virtual if node.IsVirtual
		modifiers |= Modifiers.Abstract if node.IsAbstract
		modifiers |= Modifiers.Override if node.IsOverride
#		modifiers |= Modifiers.Final if node.IsFinal
		return modifiers
		
#	def ParameterFrom(declaringMember as IMember, parameter as ParameterDeclaration):
#		return DefaultUnresolvedParameter(ParameterTypeFrom (parameter.Type),
#					Name: parameter.Name)
##					DeclaringMember: declaringMember, 
##					ReturnType: ParameterTypeFrom(parameter.Type),
##					Location: LocationOf(parameter))
					
	virtual def MethodReturnTypeFrom(method as Method):
		if method.ReturnType is not null:
			return ReturnTypeFrom(method.ReturnType)
		
		match ReturnTypeDetector().Detect(method):
			case ReturnTypeDetector.Result.Yields:
				return UnknownType ("System.Collections", "IEnumerator", 0)
			case ReturnTypeDetector.Result.Returns:
				return DefaultReturnType()
			otherwise:
				return UnknownType ("System", "Void", 0)
		
	class ReturnTypeDetector(DepthFirstVisitor):
		enum Result:
			Returns
			Yields
			None
			
		_result = Result.None
			
		def Detect(node as Method):
			VisitAllowingCancellation(node)
			return _result
			
		override def OnBlockExpression(node as BlockExpression):
			pass // skip over closures
		
#		override def OnReturnStatement(node as ReturnStatement):
#			if node.Expression is null: return
#			_result = Result.Returns
			
		override def OnYieldStatement(node as YieldStatement):
			_result = Result.Yields
			Cancel()
	
	virtual def ParameterTypeFrom(typeRef as TypeReference):
		if typeRef is null: return DefaultReturnType()
		return ReturnTypeFrom(typeRef)
		
	virtual def ReturnTypeFrom(typeRef as TypeReference) as ITypeReference:
		match typeRef:
			case SimpleTypeReference(Name: name):
				return UnknownType (string.Empty, name, 0)
#			case ArrayTypeReference(ElementType: elementType):
#				type = ReturnTypeFrom(elementType)
#				type.ArrayDimensions = 1
#				type.SetDimension(0, 1)
#				return type
			otherwise:
				return UnknownType("System", "Void", 0)
		
	def AddType(type as ITypeDefinition):
		pass
#		if _currentType is not null:
#			_currentType.Add(type)
#		else:
#			type.Namespace = _namespace
#			_result.Add(type)
		
	def WithCurrentType(type as ITypeDefinition, block as callable()):
		saved = _currentType
		_currentType = type
		try:
			block()
		ensure:
			_currentType = saved
			
	def BodyRegionOf(node as Node):
		startLocation = TextLocation (DomLocationFrom(node.LexicalInfo).Line, int.MaxValue)
		endLocation = TextLocation (DomLocationFrom(node.EndSourceLocation).Line, int.MaxValue)
#		# Start/end at the ends of lines
#		startLocation.Column = int.MaxValue
#		endLocation.Column = int.MaxValue
		return DomRegion(startLocation, endLocation)
		
	def LocationOf(node as Node):
		location = node.LexicalInfo
		return DomLocationFrom(location)
		
	def DomLocationFrom(location as SourceLocation):
		return TextLocation(location.Line, location.Column)
		
	def DefaultReturnType():
		return UnknownType ("System", "Object", 0)
