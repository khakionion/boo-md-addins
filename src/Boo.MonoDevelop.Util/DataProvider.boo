namespace Boo.MonoDevelop.Util.Completion

import System
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
		_tag = (tag as AstNode).Parent
		_ambience = ambience
		Reset()
		
	def Reset():
		_memberList.Clear()
		if(_tag isa SyntaxTree):
			types = Stack of TypeDeclaration((_tag as SyntaxTree).GetTypes (false))
			while(types.Count > 0):
				type = types.Pop()
				_memberList.Add(type)
				#for innerType in type.InnerTypes:
				#	types.Push(innerType)
		elif(_tag isa TypeDeclaration):
			_memberList.AddRange((_tag as TypeDeclaration).Members)
		_memberList.Sort({x,y|string.Compare(GetString(_ambience,x), GetString(_ambience,y), StringComparison.OrdinalIgnoreCase)})
		
	def GetString(ambience as Ambience, member as AstNode):
		flags = OutputFlags.IncludeGenerics | OutputFlags.IncludeParameters | OutputFlags.ReformatDelegates
		if(_tag isa SyntaxTree):
			flags |= OutputFlags.UseFullInnerTypeName
		return ambience.GetString(member as IEntity, flags)
		
	def GetText(index as int) as string:
		return GetString (_ambience, _memberList[index])
		
	def GetMarkup(index as int) as string:
		return GetText (index)
		
	def GetIcon(index as int) as Gdk.Pixbuf:
		return ImageService.GetPixbuf(MonoDevelop.Ide.TypeSystem.Stock.GetStockIcon (_memberList[index] as IEntity), Gtk.IconSize.Menu)
		
	def GetTag(index as int) as object:
		return _memberList[index]
		
	def ActivateItem(index as int):
		location = _memberList[index].StartLocation
		extEditor = _document.GetContent of IExtensibleTextEditor()
		if(extEditor != null):
			extEditor.SetCaretTo(Math.Max(1, location.Line), location.Column)
			

