namespace Boo.MonoDevelop.Util.Completion

import System
import System.Linq
import System.Text
import System.Collections.Generic

import MonoDevelop.Ide
import MonoDevelop.Ide.Gui
import MonoDevelop.Ide.TypeSystem
import MonoDevelop.Ide.Gui.Content
import MonoDevelop.Components

import ICSharpCode.NRefactory
import ICSharpCode.NRefactory.CSharp
import ICSharpCode.NRefactory.TypeSystem


class DataProvider(DropDownBoxListWindow.IListDataProvider):
	public IconCount as int:
		get:
			return _memberList.Count
		
	private _tag as object
	private _ambience as Ambience
	private _memberList as List of AstNode
	private _document as Document
		
	def constructor(document as Document, tag as object, ambience as Ambience):
		_memberList = List of AstNode()
		_document = document
		_tag = tag
		_ambience = ambience
		Reset()
		
	def Reset():
		_memberList.Clear()
		if(_tag isa SyntaxTree):
			foundTypes = (_tag as SyntaxTree).GetTypes (false) as IEnumerable of EntityDeclaration
			types = Stack of EntityDeclaration((_tag as SyntaxTree).GetTypes (false))
			while(types.Count > 0):
				type = types.Pop()
				_memberList.Add(type)
				for innerType in type.Children.Where({child | child isa TypeDeclaration}):
					types.Push(innerType)
		elif(_tag isa TypeDeclaration):
			_memberList.AddRange((_tag as TypeDeclaration).GetChildrenByRole (SyntaxTree.MemberRole))
		else:
			MonoDevelop.Core.LoggingService.LogError ("No fallback for {0}", _tag.GetType ().FullName)
		_memberList.Sort({x,y|string.Compare(GetString(_ambience,x), GetString(_ambience,y), StringComparison.OrdinalIgnoreCase)})
		
	def GetString(ambience as Ambience, member as AstNode):
		return GetName (member)
		
	static def GetName (node as AstNode):
		if node isa TypeDeclaration:
			sb = StringBuilder ((node as TypeDeclaration).Name)
			while node.Parent isa TypeDeclaration:
				node = node.Parent
				sb.Insert (0, (node as TypeDeclaration).Name + ".")
			return sb.ToString ()
		if node isa FieldDeclaration:
			return (node as FieldDeclaration).Variables.First ().Name
		if node isa EventDeclaration:
			return (node as EventDeclaration).Variables.First ().Name
		if (node isa EntityDeclaration):
			return (node as EntityDeclaration).Name
		if (node isa VariableInitializer):
			return (node as VariableInitializer).Name
		MonoDevelop.Core.LoggingService.LogError ("Can't get name for {0}", node.GetType ().FullName)
		return string.Empty

	def GetText(index as int) as string:
		return GetName (_memberList[index])
		
	def GetMarkup(index as int) as string:
		return GetText (index)
		
	static def GetIconStringForNode (node as AstNode):
		icon = MonoDevelop.Ide.Gui.Stock.Literal
		if (node isa TypeDeclaration):
			icon = MonoDevelop.Ide.Gui.Stock.Class
		elif (node isa NamespaceDeclaration):
			icon = MonoDevelop.Ide.Gui.Stock.NameSpace
		elif (node isa FieldDeclaration):
			icon = MonoDevelop.Ide.Gui.Stock.Field
		elif (node isa PropertyDeclaration):
			icon = MonoDevelop.Ide.Gui.Stock.Property
		elif (node isa MethodDeclaration):
			icon = MonoDevelop.Ide.Gui.Stock.Method
		elif (node isa EventDeclaration):
			icon = MonoDevelop.Ide.Gui.Stock.Event
		elif (node isa DelegateDeclaration):
			icon = MonoDevelop.Ide.Gui.Stock.Delegate
		
		return icon

	static def GetIconForNode (node as AstNode):
		return ImageService.GetPixbuf(GetIconStringForNode (node), Gtk.IconSize.Menu)
		
	def GetIcon(index as int) as Gdk.Pixbuf:
		return GetIconForNode (_memberList[index])
		
	def GetTag(index as int) as object:
		return _memberList[index]
		
	def ActivateItem(index as int):
		annotation = _memberList[index].Annotation (TextLocation)
		if null == annotation:
			location = (_memberList[index].Annotation (DomRegion) cast DomRegion).Begin
		else:
			location = annotation cast TextLocation
		extEditor = _document.GetContent of IExtensibleTextEditor()
		if(extEditor != null):
			position = extEditor.GetPositionFromLineColumn (location.Line, location.Column)
			if (position >= 0 and position < extEditor.Length):
				extEditor.SetCaretTo(Math.Max(1, location.Line), location.Column)
			

