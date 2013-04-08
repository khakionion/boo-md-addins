namespace Boo.MonoDevelop.ProjectModel

import System
import System.IO

import MonoDevelop.Projects
import MonoDevelop.Ide.TypeSystem

import ICSharpCode.NRefactory.CSharp

import Boo.Lang.Compiler

import Boo.MonoDevelop.Util

class BooParser(AbstractTypeSystemParser):
	
	_compiler = Boo.Lang.Compiler.BooCompiler()
	
	def constructor():
		# super("Boo", BooMimeType)
		super()
		pipeline = CompilerPipeline() { Steps.IntroduceModuleClasses() }
		_compiler.Parameters.Pipeline = pipeline
		
#	override def CanParse(fileName as string):
#		return Path.GetExtension(fileName).ToLower() == ".boo"

	override def Parse(storeAst as bool, fileName as string, reader as TextReader, project as Project):
		document = DefaultParsedDocument(fileName)
		
#		try:
#			index = ProjectIndexFactory.ForProject(project)
#			assert index is not null
#			module = index.Parse(fileName, reader.ReadToEnd ())
#			IntroduceModuleClasses(module).Accept(DomConversionVisitor(document.CompilationUnit))
#		except e:
#			LogError e
		
		return document
		
#	override def CreateResolver(dom as SyntaxTree, editor, fileName as string):
#		doc = cast(MonoDevelop.Ide.Gui.Document, editor)
#		return BooResolver(dom, doc.CompilationUnit, fileName)
		
	private def IntroduceModuleClasses(module as Ast.Module):
		return _compiler.Run(Ast.CompileUnit(module.CloneNode())).CompileUnit
		
