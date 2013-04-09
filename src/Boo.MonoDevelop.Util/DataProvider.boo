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
			types = Stack of TypeDeclaration((_tag as SyntaxTree).GetTypes (false))
			while(types.Count > 0):
				type = types.Pop()
				_memberList.Add(type)
				for innerType in type.Children.Where({child | child isa TypeDeclaration}):
					types.Push(innerType)
		elif(_tag isa TypeDeclaration):
			_memberList.AddRange((_tag as TypeDeclaration).Members)
		MonoDevelop.Core.LoggingService.LogError ("Publishing {0} members for {1}", IconCount, _document.Name)
		_memberList.Sort({x,y|string.Compare(GetString(_ambience,x), GetString(_ambience,y), StringComparison.OrdinalIgnoreCase)})
		
	def GetString(ambience as Ambience, member as AstNode):
		return GetName (member)
		
	def GetName (node as AstNode):
		if _tag isa SyntaxTree:
			if node isa TypeDeclaration:
				sb = StringBuilder ((node as TypeDeclaration).Name)
				while node.Parent isa TypeDeclaration:
					node = node.Parent
					sb.Insert (0, (node as TypeDeclaration).Name + ".")
				return sb.ToString ()
				
			if (node is EntityDeclaration):
				return (node as EntityDeclaration).Name
			return (node as VariableInitializer).Name
		return string.Empty

	def GetText(index as int) as string:
		return GetName (_memberList[index])
		
	def GetMarkup(index as int) as string:
		return GetText (index)
		
	def GetIcon(index as int) as Gdk.Pixbuf:
		icon = "md-field"
		if (_memberList[index] isa TypeDeclaration):
			icon = "md-class"
		elif (_memberList[index] isa NamespaceDeclaration):
			icon = "md-name-space"
		elif (_memberList[index] isa FieldDeclaration):
			icon = "md-field"
		elif (_memberList[index] isa PropertyDeclaration):
			icon = "md-property"
		elif (_memberList[index] isa MethodDeclaration):
			icon = "md-method"
		return ImageService.GetPixbuf(icon, Gtk.IconSize.Menu)
		
	def GetTag(index as int) as object:
		return _memberList[index]
		
	def ActivateItem(index as int):
		location = _memberList[index].StartLocation
		extEditor = _document.GetContent of IExtensibleTextEditor()
		if(extEditor != null):
			extEditor.SetCaretTo(Math.Max(1, location.Line), location.Column)
			

