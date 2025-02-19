// Copyright (c) 2019-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module ast

import v.token
import v.table
import v.errors

pub type TypeDecl = AliasTypeDecl | FnTypeDecl | SumTypeDecl

pub type Expr = AnonFn | ArrayDecompose | ArrayInit | AsCast | Assoc | AtExpr | BoolLiteral |
	CTempVar | CallExpr | CastExpr | ChanInit | CharLiteral | Comment | ComptimeCall |
	ComptimeSelector | ConcatExpr | DumpExpr | EnumVal | FloatLiteral | GoExpr | Ident |
	IfExpr | IfGuardExpr | IndexExpr | InfixExpr | IntegerLiteral | Likely | LockExpr |
	MapInit | MatchExpr | None | OffsetOf | OrExpr | ParExpr | PostfixExpr | PrefixExpr |
	RangeExpr | SelectExpr | SelectorExpr | SizeOf | SqlExpr | StringInterLiteral | StringLiteral |
	StructInit | Type | TypeOf | UnsafeExpr

pub type Stmt = AssertStmt | AssignStmt | Block | BranchStmt | CompFor | ConstDecl | DeferStmt |
	EnumDecl | ExprStmt | FnDecl | ForCStmt | ForInStmt | ForStmt | GlobalDecl | GoStmt |
	GotoLabel | GotoStmt | HashStmt | Import | InterfaceDecl | Module | Return | SqlStmt |
	StructDecl | TypeDecl

// NB: when you add a new Expr or Stmt type with a .pos field, remember to update
// the .position() token.Position methods too.
pub type ScopeObject = ConstField | GlobalField | Var

// TOOD: replace table.Param
pub type Node = ConstField | EnumField | Expr | Field | File | GlobalField | IfBranch |
	MatchBranch | ScopeObject | SelectBranch | Stmt | StructField | StructInitField |
	table.Param

pub struct Type {
pub:
	typ table.Type
	pos token.Position
}

// `{stmts}` or `unsafe {stmts}`
pub struct Block {
pub:
	stmts     []Stmt
	is_unsafe bool
	pos       token.Position
}

// | IncDecStmt k
// Stand-alone expression in a statement list.
pub struct ExprStmt {
pub:
	expr     Expr
	pos      token.Position
	comments []Comment
	is_expr  bool
pub mut:
	typ table.Type
}

pub struct IntegerLiteral {
pub:
	val string
	pos token.Position
}

pub struct FloatLiteral {
pub:
	val string
	pos token.Position
}

pub struct StringLiteral {
pub:
	val      string
	is_raw   bool
	language table.Language
	pos      token.Position
}

// 'name: $name'
pub struct StringInterLiteral {
pub:
	vals       []string
	exprs      []Expr
	fwidths    []int
	precisions []int
	pluss      []bool
	fills      []bool
	fmt_poss   []token.Position
	pos        token.Position
pub mut:
	expr_types []table.Type
	fmts       []byte
	need_fmts  []bool // an explicit non-default fmt required, e.g. `x`
}

pub struct CharLiteral {
pub:
	val string
	pos token.Position
}

pub struct BoolLiteral {
pub:
	val bool
	pos token.Position
}

// `foo.bar`
pub struct SelectorExpr {
pub:
	pos        token.Position
	field_name string
	is_mut     bool // is used for the case `if mut ident.selector is MyType {`, it indicates if the root ident is mutable
	mut_pos    token.Position
	next_token token.Kind
pub mut:
	expr            Expr       // expr.field_name
	expr_type       table.Type // type of `Foo` in `Foo.bar`
	typ             table.Type // type of the entire thing (`Foo.bar`)
	name_type       table.Type // T in `T.name` or typeof in `typeof(expr).name`
	scope           &Scope
	from_embed_type table.Type // holds the type of the embed that the method is called from
}

// root_ident returns the origin ident where the selector started.
pub fn (e &SelectorExpr) root_ident() Ident {
	mut root := e.expr
	for root is SelectorExpr {
		// TODO: remove this line
		selector_expr := root as SelectorExpr
		root = selector_expr.expr
	}
	return root as Ident
}

// module declaration
pub struct Module {
pub:
	name       string // encoding.base64
	short_name string // base64
	attrs      []table.Attr
	pos        token.Position
	name_pos   token.Position // `name` in import name
	is_skipped bool // module main can be skipped in single file programs
}

pub struct StructField {
pub:
	pos              token.Position
	type_pos         token.Position
	comments         []Comment
	default_expr     Expr
	has_default_expr bool
	attrs            []table.Attr
	is_public        bool
pub mut:
	name string
	typ  table.Type
}

pub struct Field {
pub:
	name string
	pos  token.Position
pub mut:
	typ table.Type
}

// const field in const declaration group
pub struct ConstField {
pub:
	mod    string
	name   string
	expr   Expr // the value expr of field; everything after `=`
	is_pub bool
	pos    token.Position
pub mut:
	typ      table.Type // the type of the const field, it can be any type in V
	comments []Comment  // comments before current const field
}

// const declaration
pub struct ConstDecl {
pub:
	is_pub bool
	pos    token.Position
pub mut:
	fields       []ConstField // all the const fields in the `const (...)` block
	end_comments []Comment    // comments that after last const field
	is_block     bool // const() block
}

pub struct StructDecl {
pub:
	pos       token.Position
	name      string
	gen_types []table.Type
	is_pub    bool
	// _pos fields for vfmt
	mut_pos      int // mut:
	pub_pos      int // pub:
	pub_mut_pos  int // pub mut:
	global_pos   int // __global:
	module_pos   int // module:
	language     table.Language
	is_union     bool
	attrs        []table.Attr
	end_comments []Comment
	embeds       []Embed
pub mut:
	fields []StructField
}

pub struct Embed {
pub:
	typ table.Type
	pos token.Position
}

pub struct StructEmbedding {
pub:
	name string
	typ  table.Type
	pos  token.Position
}

pub struct InterfaceDecl {
pub:
	name         string
	field_names  []string
	is_pub       bool
	methods      []FnDecl
	mut_pos      int // mut:
	fields       []StructField
	pos          token.Position
	pre_comments []Comment
}

pub struct StructInitField {
pub:
	expr          Expr
	pos           token.Position
	comments      []Comment
	next_comments []Comment
pub mut:
	name          string
	typ           table.Type
	expected_type table.Type
}

pub struct StructInitEmbed {
pub:
	expr          Expr
	pos           token.Position
	comments      []Comment
	next_comments []Comment
pub mut:
	name          string
	typ           table.Type
	expected_type table.Type
}

pub struct StructInit {
pub:
	pos      token.Position
	is_short bool
pub mut:
	unresolved           bool
	pre_comments         []Comment
	typ                  table.Type
	update_expr          Expr
	update_expr_type     table.Type
	update_expr_comments []Comment
	has_update_expr      bool
	fields               []StructInitField
	embeds               []StructInitEmbed
}

// import statement
pub struct Import {
pub:
	mod       string // the module name of the import
	alias     string // the `x` in `import xxx as x`
	pos       token.Position
	mod_pos   token.Position
	alias_pos token.Position
pub mut:
	syms          []ImportSymbol // the list of symbols in `import {symbol1, symbol2}`
	comments      []Comment
	next_comments []Comment
}

// import symbol,for import {symbol} syntax
pub struct ImportSymbol {
pub:
	pos  token.Position
	name string
}

// anonymous function
pub struct AnonFn {
pub mut:
	decl    FnDecl
	typ     table.Type // the type of anonymous fn. Both .typ and .decl.name are auto generated
	has_gen bool       // has been generated
}

// function or method declaration
pub struct FnDecl {
pub:
	name            string
	mod             string
	params          []table.Param
	is_deprecated   bool
	is_pub          bool
	is_variadic     bool
	is_anon         bool
	is_manualfree   bool // true, when [manualfree] is used on a fn
	is_main         bool // true for `fn main()`
	is_test         bool // true for `fn test_abcde`
	is_conditional  bool // true for `[if abc] fn abc(){}`
	receiver        Field
	receiver_pos    token.Position // `(u User)` in `fn (u User) name()` position
	is_method       bool
	method_type_pos token.Position // `User` in ` fn (u User)` position
	method_idx      int
	rec_mut         bool // is receiver mutable
	rec_share       table.ShareType
	language        table.Language
	no_body         bool // just a definition `fn C.malloc()`
	is_builtin      bool // this function is defined in builtin/strconv
	pos             token.Position // function declaration position
	body_pos        token.Position // function bodys position
	file            string
	generic_params  []GenericParam
	is_direct_arr   bool // direct array access
	attrs           []table.Attr
	skip_gen        bool // this function doesn't need to be generated (for example [if foo])
pub mut:
	stmts         []Stmt
	defer_stmts   []DeferStmt
	return_type   table.Type
	has_return    bool
	comments      []Comment // comments *after* the header, but *before* `{`; used for InterfaceDecl
	next_comments []Comment // coments that are one line after the decl; used for InterfaceDecl
	source_file   &File = 0
	scope         &Scope
	label_names   []string
}

pub struct GenericParam {
pub:
	name string
}

// break, continue
pub struct BranchStmt {
pub:
	kind  token.Kind
	label string
	pos   token.Position
}

// function or method call expr
pub struct CallExpr {
pub:
	pos token.Position
	mod string
pub mut:
	name               string // left.name()
	is_method          bool
	is_field           bool // temp hack, remove ASAP when re-impl CallExpr / Selector (joe)
	args               []CallArg
	expected_arg_types []table.Type
	language           table.Language
	or_block           OrExpr
	left               Expr       // `user` in `user.register()`
	left_type          table.Type // type of `user`
	receiver_type      table.Type // User
	return_type        table.Type
	should_be_skipped  bool
	generic_types      []table.Type
	generic_list_pos   token.Position
	free_receiver      bool // true if the receiver expression needs to be freed
	scope              &Scope
	from_embed_type    table.Type // holds the type of the embed that the method is called from
	comments           []Comment
}

/*
pub struct AutofreeArgVar {
	name string
	idx  int
}
*/
// function call argument: `f(callarg)`
pub struct CallArg {
pub:
	is_mut   bool
	share    table.ShareType
	expr     Expr
	comments []Comment
pub mut:
	typ             table.Type
	is_tmp_autofree bool // this tells cgen that a tmp variable has to be used for the arg expression in order to free it after the call
	pos             token.Position
	// tmp_name        string // for autofree
}

// function return statement
pub struct Return {
pub:
	pos      token.Position
	exprs    []Expr
	comments []Comment
pub mut:
	types []table.Type
}

/*
pub enum Expr {
	Binary(InfixExpr)
	If(IfExpr)
	Integer(IntegerExpr)
}
*/
/*
pub struct Stmt {
	pos int
	//end int
}
*/
pub struct Var {
pub:
	name            string
	expr            Expr
	share           table.ShareType
	is_mut          bool
	is_autofree_tmp bool
	is_arg          bool // fn args should not be autofreed
	is_auto_deref   bool
pub mut:
	typ            table.Type
	orig_type      table.Type   // original sumtype type; 0 if it's not a sumtype
	sum_type_casts []table.Type // nested sum types require nested smart casting, for that a list of types is needed
	// TODO: move this to a real docs site later
	// 10 <- original type (orig_type)
	//   [11, 12, 13] <- cast order (sum_type_casts)
	//        12 <- the current casted type (typ)
	pos        token.Position
	is_used    bool
	is_changed bool // to detect mutable vars that are never changed
	//
	// (for setting the position after the or block for autofree)
	is_or  bool // `x := foo() or { ... }`
	is_tmp bool // for tmp for loop vars, so that autofree can skip them
}

// used for smartcasting only
// struct fields change type in scopes
pub struct ScopeStructField {
pub:
	struct_type    table.Type // type of struct
	name           string
	pos            token.Position
	typ            table.Type
	sum_type_casts []table.Type // nested sum types require nested smart casting, for that a list of types is needed
	orig_type      table.Type   // original sumtype type; 0 if it's not a sumtype
	// TODO: move this to a real docs site later
	// 10 <- original type (orig_type)
	//   [11, 12, 13] <- cast order (sum_type_casts)
	//        12 <- the current casted type (typ)
}

pub struct GlobalField {
pub:
	name     string
	expr     Expr
	has_expr bool
	pos      token.Position
pub mut:
	typ      table.Type
	comments []Comment
}

pub struct GlobalDecl {
pub:
	pos token.Position
pub mut:
	fields       []GlobalField
	end_comments []Comment
}

pub struct EmbeddedFile {
pub:
	rpath string // used in the source code, as an ID/key to the embed
	apath string // absolute path during compilation to the resource
}

// Each V source file is represented by one ast.File structure.
// When the V compiler runs, the parser will fill an []ast.File.
// That array is then passed to V's checker.
pub struct File {
pub:
	path         string // absolute path of the source file - '/projects/v/file.v'
	path_base    string // file name - 'file.v' (useful for tracing)
	mod          Module // the module of the source file (from `module xyz` at the top)
	global_scope &Scope
pub mut:
	scope            &Scope
	stmts            []Stmt            // all the statements in the source file
	imports          []Import          // all the imports
	auto_imports     []string          // imports that were implicitely added
	embedded_files   []EmbeddedFile    // list of files to embed in the binary
	imported_symbols map[string]string // used for `import {symbol}`, it maps symbol => module.symbol
	errors           []errors.Error    // all the checker errors in the file
	warnings         []errors.Warning  // all the checker warings in the file
	generic_fns      []&FnDecl
}

pub struct IdentFn {
pub mut:
	typ table.Type
}

// TODO: (joe) remove completely, use ident.obj
// instead which points to the scope object
pub struct IdentVar {
pub mut:
	typ         table.Type
	is_mut      bool
	is_static   bool
	is_optional bool
	share       table.ShareType
}

pub type IdentInfo = IdentFn | IdentVar

pub enum IdentKind {
	unresolved
	blank_ident
	variable
	constant
	global
	function
}

// A single identifier
pub struct Ident {
pub:
	language table.Language
	tok_kind token.Kind
	pos      token.Position
	mut_pos  token.Position
pub mut:
	scope  &Scope
	obj    ScopeObject
	mod    string
	name   string
	kind   IdentKind
	info   IdentInfo
	is_mut bool
}

pub fn (i &Ident) var_info() IdentVar {
	match mut i.info {
		IdentVar {
			return i.info
		}
		else {
			// return IdentVar{}
			panic('Ident.var_info(): info is not IdentVar variant')
		}
	}
}

// left op right
// See: token.Kind.is_infix
pub struct InfixExpr {
pub:
	op  token.Kind
	pos token.Position
pub mut:
	left        Expr
	right       Expr
	left_type   table.Type
	right_type  table.Type
	auto_locked string
	or_block    OrExpr
}

// ++, --
pub struct PostfixExpr {
pub:
	op   token.Kind
	expr Expr
	pos  token.Position
pub mut:
	auto_locked string
}

// See: token.Kind.is_prefix
pub struct PrefixExpr {
pub:
	op  token.Kind
	pos token.Position
pub mut:
	right_type table.Type
	right      Expr
	or_block   OrExpr
	is_option  bool // IfGuard
}

pub struct IndexExpr {
pub:
	pos     token.Position
	index   Expr // [0], RangeExpr [start..end] or map[key]
	or_expr OrExpr
pub mut:
	left      Expr
	left_type table.Type // array, map, fixed array
	is_setter bool
	is_map    bool
	is_array  bool
	is_farray bool
	is_option bool // IfGuard
}

pub struct IfExpr {
pub:
	is_comptime   bool
	tok_kind      token.Kind
	left          Expr // `a` in `a := if ...`
	pos           token.Position
	post_comments []Comment
pub mut:
	branches []IfBranch // includes all `else if` branches
	is_expr  bool
	typ      table.Type
	has_else bool
}

pub struct IfBranch {
pub:
	cond     Expr
	pos      token.Position
	body_pos token.Position
	comments []Comment
pub mut:
	stmts     []Stmt
	smartcast bool // true when cond is `x is SumType`, set in checker.if_expr // no longer needed with union sum types TODO: remove
	scope     &Scope
}

pub struct UnsafeExpr {
pub:
	expr Expr
	pos  token.Position
}

pub struct LockExpr {
pub:
	stmts    []Stmt
	is_rlock []bool
	pos      token.Position
pub mut:
	lockeds []Ident // `x`, `y` in `lock x, y {`
	is_expr bool
	typ     table.Type
}

pub struct MatchExpr {
pub:
	tok_kind token.Kind
	cond     Expr
	branches []MatchBranch
	pos      token.Position
	comments []Comment // comments before the first branch
pub mut:
	is_expr       bool // returns a value
	return_type   table.Type
	cond_type     table.Type // type of `x` in `match x {`
	expected_type table.Type // for debugging only
	is_sum_type   bool
}

pub struct MatchBranch {
pub:
	exprs         []Expr      // left side
	ecmnts        [][]Comment // inline comments for each left side expr
	stmts         []Stmt      // right side
	pos           token.Position
	is_else       bool
	post_comments []Comment // comments below ´... }´
pub mut:
	scope &Scope
}

pub struct SelectExpr {
pub:
	branches      []SelectBranch
	pos           token.Position
	has_exception bool
pub mut:
	is_expr       bool       // returns a value
	expected_type table.Type // for debugging only
}

pub struct SelectBranch {
pub:
	stmt          Stmt   // `a := <-ch` or `ch <- a`
	stmts         []Stmt // right side
	pos           token.Position
	comment       Comment // comment above `select {`
	is_else       bool
	is_timeout    bool
	post_comments []Comment
}

pub enum CompForKind {
	methods
	fields
}

pub struct CompFor {
pub:
	val_var string
	stmts   []Stmt
	kind    CompForKind
	pos     token.Position
	typ_pos token.Position
pub mut:
	// expr    Expr
	typ table.Type
}

pub struct ForStmt {
pub:
	cond   Expr
	stmts  []Stmt
	is_inf bool // `for {}`
	pos    token.Position
pub mut:
	label string // `label: for {`
	scope &Scope
}

pub struct ForInStmt {
pub:
	key_var    string
	val_var    string
	cond       Expr
	is_range   bool
	high       Expr // `10` in `for i in 0..10 {`
	stmts      []Stmt
	pos        token.Position
	val_is_mut bool // `for mut val in vals {` means that modifying `val` will modify the array
	// and the array cannot be indexed inside the loop
pub mut:
	key_type  table.Type
	val_type  table.Type
	cond_type table.Type
	kind      table.Kind // array/map/string
	label     string     // `label: for {`
	scope     &Scope
}

pub struct ForCStmt {
pub:
	init     Stmt // i := 0;
	has_init bool
	cond     Expr // i < 10;
	has_cond bool
	inc      Stmt // i++; i += 2
	has_inc  bool
	is_multi bool // for a,b := 0,1; a < 10; a,b = a+b, a {...}
	stmts    []Stmt
	pos      token.Position
pub mut:
	label string // `label: for {`
	scope &Scope
}

// #include etc
pub struct HashStmt {
pub:
	mod         string
	pos         token.Position
	source_file string
pub mut:
	val  string // example: 'include <openssl/rand.h> # please install openssl // comment'
	kind string // : 'include'
	main string // : '<openssl/rand.h>'
	msg  string // : 'please install openssl'
}

/*
// filter(), map(), sort()
pub struct Lambda {
pub:
	name string
}
*/
// variable assign statement
pub struct AssignStmt {
pub:
	op           token.Kind // include: =,:=,+=,-=,*=,/= and so on; for a list of all the assign operators, see vlib/token/token.v
	pos          token.Position
	comments     []Comment
	end_comments []Comment
pub mut:
	right         []Expr
	left          []Expr
	left_types    []table.Type
	right_types   []table.Type
	is_static     bool // for translated code only
	is_simple     bool // `x+=2` in `for x:=1; ; x+=2`
	has_cross_var bool
}

pub struct AsCast {
pub:
	expr Expr
	typ  table.Type
	pos  token.Position
pub mut:
	expr_type table.Type
}

// an enum value, like OS.macos or .macos
pub struct EnumVal {
pub:
	enum_name string
	val       string
	mod       string // for full path `mod_Enum_val`
	pos       token.Position
pub mut:
	typ table.Type
}

// enum field in enum declaration
pub struct EnumField {
pub:
	name          string
	pos           token.Position
	comments      []Comment // comment after Enumfield in the same line
	next_comments []Comment // comments between current EnumField and next EnumField
	expr          Expr      // the value of current EnumField; 123 in `ename = 123`
	has_expr      bool      // true, when .expr has a value
}

// enum declaration
pub struct EnumDecl {
pub:
	name             string
	is_pub           bool
	is_flag          bool         // true when the enum has [flag] tag,for bit field enum
	is_multi_allowed bool         // true when the enum has [_allow_multiple_values] tag
	comments         []Comment    // comments before the first EnumField
	fields           []EnumField  // all the enum fields
	attrs            []table.Attr // attributes of enum declaration
	pos              token.Position
}

pub struct AliasTypeDecl {
pub:
	name        string
	is_pub      bool
	parent_type table.Type
	pos         token.Position
	comments    []Comment
}

// New implementation of sum types
pub struct SumTypeDecl {
pub:
	name     string
	is_pub   bool
	pos      token.Position
	comments []Comment
	typ      table.Type
pub mut:
	variants []SumTypeVariant
}

pub struct SumTypeVariant {
pub:
	typ table.Type
	pos token.Position
}

pub struct FnTypeDecl {
pub:
	name     string
	is_pub   bool
	typ      table.Type
	pos      token.Position
	comments []Comment
}

// TODO: handle this differently
// v1 excludes non current os ifdefs so
// the defer's never get added in the first place
pub struct DeferStmt {
pub:
	stmts []Stmt
	pos   token.Position
pub mut:
	ifdef     string
	idx_in_fn int = -1 // index in FnDecl.defer_stmts
}

// `(3+4)`
pub struct ParExpr {
pub:
	expr Expr
	pos  token.Position
}

pub struct GoStmt {
pub:
	pos token.Position
pub mut:
	call_expr CallExpr
}

pub struct GoExpr {
pub:
	pos token.Position
pub mut:
	go_stmt GoStmt
mut:
	return_type table.Type
}

pub struct GotoLabel {
pub:
	name string
	pos  token.Position
}

pub struct GotoStmt {
pub:
	name string
	pos  token.Position
}

pub struct ArrayInit {
pub:
	pos           token.Position // `[]` in []Type{} position
	elem_type_pos token.Position // `Type` in []Type{} position
	exprs         []Expr      // `[expr, expr]` or `[expr]Type{}` for fixed array
	ecmnts        [][]Comment // optional iembed comments after each expr
	pre_cmnts     []Comment
	is_fixed      bool
	has_val       bool // fixed size literal `[expr, expr]!`
	mod           string
	len_expr      Expr // len: expr
	cap_expr      Expr // cap: expr
	default_expr  Expr // init: expr
	has_len       bool
	has_cap       bool
	has_default   bool
pub mut:
	expr_types []table.Type // [Dog, Cat] // also used for interface_types
	elem_type  table.Type   // element type
	typ        table.Type   // array type
}

pub struct ArrayDecompose {
pub:
	expr Expr
	pos  token.Position
pub mut:
	expr_type table.Type
	arg_type  table.Type
}

pub struct ChanInit {
pub:
	pos      token.Position
	cap_expr Expr
	has_cap  bool
pub mut:
	typ       table.Type
	elem_type table.Type
}

pub struct MapInit {
pub:
	pos       token.Position
	keys      []Expr
	vals      []Expr
	comments  [][]Comment // comments after key-value pairs
	pre_cmnts []Comment   // comments before the first key-value pair
pub mut:
	typ        table.Type
	key_type   table.Type
	value_type table.Type
}

// s[10..20]
pub struct RangeExpr {
pub:
	low      Expr
	high     Expr
	has_high bool
	has_low  bool
	pos      token.Position
}

// NB: &string(x) gets parsed as ast.PrefixExpr{ right: ast.CastExpr{...} }
// TODO: that is very likely a parsing bug. It should get parsed as just
// ast.CastExpr{...}, where .typname is '&string' instead.
// The current situation leads to special cases in vfmt and cgen
// (see prefix_expr_cast_expr in fmt.v, and .is_amp in cgen.v)
// .in_prexpr is also needed because of that, because the checker needs to
// show warnings about the deprecated C->V conversions `string(x)` and
// `string(x,y)`, while skipping the real pointer casts like `&string(x)`.
pub struct CastExpr {
pub:
	expr Expr       // `buf` in `string(buf, n)`
	arg  Expr       // `n` in `string(buf, n)`
	typ  table.Type // `string` TODO rename to `type_to_cast_to`
	pos  token.Position
pub mut:
	typname   string     // TypeSymbol.name
	expr_type table.Type // `byteptr`
	has_arg   bool
	in_prexpr bool // is the parent node an ast.PrefixExpr
}

pub struct AssertStmt {
pub:
	pos token.Position
pub mut:
	expr Expr
}

// `if [x := opt()] {`
pub struct IfGuardExpr {
pub:
	var_name string
	pos      token.Position
pub mut:
	expr      Expr
	expr_type table.Type
}

pub enum OrKind {
	absent
	block
	propagate
}

// `or { ... }`
pub struct OrExpr {
pub:
	stmts []Stmt
	kind  OrKind
	pos   token.Position
}

/*
// `or { ... }`
pub struct OrExpr2 {
pub:
	call_expr CallExpr
	stmts     []Stmt // inside `or { }`
	kind      OrKind
	pos       token.Position
}
*/

// deprecated
pub struct Assoc {
pub:
	var_name string
	fields   []string
	exprs    []Expr
	pos      token.Position
pub mut:
	typ   table.Type
	scope &Scope
}

pub struct SizeOf {
pub:
	is_type bool
	expr    Expr // checker uses this to set typ
	pos     token.Position
pub mut:
	typ table.Type
}

pub struct OffsetOf {
pub:
	struct_type table.Type
	field       string
	pos         token.Position
}

pub struct Likely {
pub:
	expr      Expr
	pos       token.Position
	is_likely bool // false for _unlikely_
}

pub struct TypeOf {
pub:
	expr Expr
	pos  token.Position
pub mut:
	expr_type table.Type
}

pub struct DumpExpr {
pub:
	expr Expr
	pos  token.Position
pub mut:
	expr_type table.Type
	cname     string // filled in the checker
}

pub struct Comment {
pub:
	text     string
	is_multi bool
	line_nr  int
	pos      token.Position
}

pub struct ConcatExpr {
pub:
	vals []Expr
	pos  token.Position
pub mut:
	return_type table.Type
}

// @FN, @STRUCT, @MOD etc. See full list in token.valid_at_tokens
pub struct AtExpr {
pub:
	name string
	pos  token.Position
	kind token.AtKind
pub mut:
	val string
}

pub struct ComptimeSelector {
pub:
	has_parens bool // if $() is used, for vfmt
	left       Expr
	field_expr Expr
	pos        token.Position
pub mut:
	left_type table.Type
	typ       table.Type
}

pub struct ComptimeCall {
pub:
	pos         token.Position
	has_parens  bool // if $() is used, for vfmt
	method_name string
	method_pos  token.Position
	scope       &Scope
	left        Expr
	args_var    string
	//
	is_vweb   bool
	vweb_tmpl File
	//
	is_embed   bool
	embed_file EmbeddedFile
	//
	is_env  bool
	env_pos token.Position
pub mut:
	sym         table.TypeSymbol
	result_type table.Type
	env_value   string
	args        []CallArg
}

pub struct None {
pub:
	pos token.Position
	foo int // todo
}

pub enum SqlStmtKind {
	insert
	update
	delete
}

pub struct SqlStmt {
pub:
	kind            SqlStmtKind
	db_expr         Expr   // `db` in `sql db {`
	object_var_name string // `user`
	pos             token.Position
	where_expr      Expr
	updated_columns []string // for `update set x=y`
	update_exprs    []Expr   // for `update`
pub mut:
	table_expr  Type
	fields      []table.Field
	sub_structs map[int]SqlStmt
}

pub struct SqlExpr {
pub:
	typ         table.Type
	is_count    bool
	db_expr     Expr // `db` in `sql db {`
	has_where   bool
	has_offset  bool
	offset_expr Expr
	has_order   bool
	order_expr  Expr
	has_desc    bool
	is_array    bool
	pos         token.Position
	has_limit   bool
	limit_expr  Expr
pub mut:
	where_expr  Expr
	table_expr  Type
	fields      []table.Field
	sub_structs map[int]SqlExpr
}

[inline]
pub fn (expr Expr) is_blank_ident() bool {
	match expr {
		Ident { return expr.kind == .blank_ident }
		else { return false }
	}
}

pub fn (expr Expr) position() token.Position {
	// all uncommented have to be implemented
	match expr {
		// KEKW2
		AnonFn {
			return expr.decl.pos
		}
		ArrayDecompose, ArrayInit, AsCast, Assoc, AtExpr, BoolLiteral, CallExpr, CastExpr, ChanInit,
		CharLiteral, ConcatExpr, Comment, ComptimeCall, ComptimeSelector, EnumVal, DumpExpr, FloatLiteral,
		GoExpr, Ident, IfExpr, IndexExpr, IntegerLiteral, Likely, LockExpr, MapInit, MatchExpr,
		None, OffsetOf, OrExpr, ParExpr, PostfixExpr, PrefixExpr, RangeExpr, SelectExpr, SelectorExpr,
		SizeOf, SqlExpr, StringInterLiteral, StringLiteral, StructInit, Type, TypeOf, UnsafeExpr
		 {
			return expr.pos
		}
		IfGuardExpr {
			return expr.expr.position()
		}
		InfixExpr {
			left_pos := expr.left.position()
			right_pos := expr.right.position()
			return token.Position{
				line_nr: expr.pos.line_nr
				pos: left_pos.pos
				len: right_pos.pos - left_pos.pos + right_pos.len
				last_line: right_pos.last_line
			}
		}
		CTempVar {
			return token.Position{}
		}
		// Please, do NOT use else{} here.
		// This match is exhaustive *on purpose*, to help force
		// maintaining/implementing proper .pos fields.
	}
}

pub fn (expr Expr) is_lvalue() bool {
	match expr {
		Ident { return true }
		CTempVar { return true }
		IndexExpr { return expr.left.is_lvalue() }
		SelectorExpr { return expr.expr.is_lvalue() }
		ParExpr { return expr.expr.is_lvalue() } // for var := &{...(*pointer_var)}
		PrefixExpr { return expr.right.is_lvalue() }
		else {}
	}
	return false
}

pub fn (expr Expr) is_expr() bool {
	match expr {
		IfExpr { return expr.is_expr }
		LockExpr { return expr.is_expr }
		MatchExpr { return expr.is_expr }
		SelectExpr { return expr.is_expr }
		else {}
	}
	return true
}

pub fn (expr Expr) is_lit() bool {
	return match expr {
		BoolLiteral, StringLiteral, IntegerLiteral { true }
		else { false }
	}
}

pub fn (expr Expr) is_auto_deref_var() bool {
	match expr {
		Ident {
			if expr.obj is Var {
				if expr.obj.is_auto_deref {
					return true
				}
			}
		}
		PrefixExpr {
			if expr.op == .amp && expr.right.is_auto_deref_var() {
				return true
			}
		}
		else {}
	}
	return false
}

// check if stmt can be an expression in C
pub fn (stmt Stmt) check_c_expr() ? {
	match stmt {
		AssignStmt {
			return
		}
		ExprStmt {
			if stmt.expr.is_expr() {
				return
			}
			return error('unsupported statement (`$stmt.expr.type_name()`)')
		}
		else {}
	}
	return error('unsupported statement (`$stmt.type_name()`)')
}

// CTempVar is used in cgen only, to hold nodes for temporary variables
pub struct CTempVar {
pub:
	name   string     // the name of the C temporary variable; used by g.expr(x)
	orig   Expr       // the original expression, which produced the C temp variable; used by x.str()
	typ    table.Type // the type of the original expression
	is_ptr bool       // whether the type is a pointer
}

pub fn (node Node) position() token.Position {
	match node {
		Stmt {
			mut pos := node.pos
			if node is Import {
				for sym in node.syms {
					pos = pos.extend(sym.pos)
				}
			}
			return pos
		}
		Expr {
			return node.position()
		}
		StructField {
			return node.pos.extend(node.type_pos)
		}
		MatchBranch, SelectBranch, Field, EnumField, ConstField, StructInitField, GlobalField,
		table.Param {
			return node.pos
		}
		IfBranch {
			return node.pos.extend(node.body_pos)
		}
		ScopeObject {
			match node {
				ConstField, GlobalField, Var { return node.pos }
			}
		}
		File {
			mut pos := token.Position{}
			if node.stmts.len > 0 {
				first_pos := node.stmts.first().pos
				last_pos := node.stmts.last().pos
				pos = first_pos.extend_with_last_line(last_pos, last_pos.line_nr)
			}
			return pos
		}
	}
}

pub fn (node Node) children() []Node {
	mut children := []Node{}
	if node is Expr {
		match node {
			StringInterLiteral, Assoc, ArrayInit {
				return node.exprs.map(Node(it))
			}
			SelectorExpr, PostfixExpr, UnsafeExpr, AsCast, ParExpr, IfGuardExpr, SizeOf, Likely,
			TypeOf, ArrayDecompose {
				children << node.expr
			}
			LockExpr, OrExpr {
				return node.stmts.map(Node(it))
			}
			StructInit {
				return node.fields.map(Node(it))
			}
			AnonFn {
				children << Stmt(node.decl)
			}
			CallExpr {
				children << node.left
				children << Expr(node.or_block)
			}
			InfixExpr {
				children << node.left
				children << node.right
			}
			PrefixExpr {
				children << node.right
			}
			IndexExpr {
				children << node.left
				children << node.index
			}
			IfExpr {
				children << node.left
				children << node.branches.map(Node(it))
			}
			MatchExpr {
				children << node.cond
				children << node.branches.map(Node(it))
			}
			SelectExpr {
				return node.branches.map(Node(it))
			}
			ChanInit {
				children << node.cap_expr
			}
			MapInit {
				children << node.keys.map(Node(it))
				children << node.vals.map(Node(it))
			}
			RangeExpr {
				children << node.low
				children << node.high
			}
			CastExpr {
				children << node.expr
				children << node.arg
			}
			ConcatExpr {
				return node.vals.map(Node(it))
			}
			ComptimeCall, ComptimeSelector {
				children << node.left
			}
			else {}
		}
	} else if node is Stmt {
		match node {
			Block, DeferStmt, ForCStmt, ForInStmt, ForStmt, CompFor {
				return node.stmts.map(Node(it))
			}
			ExprStmt, AssertStmt {
				children << node.expr
			}
			InterfaceDecl {
				return node.methods.map(Node(Stmt(it)))
			}
			AssignStmt {
				children << node.left.map(Node(it))
				children << node.right.map(Node(it))
			}
			Return {
				return node.exprs.map(Node(it))
			}
			// NB: these four decl nodes cannot be merged as one branch
			StructDecl {
				return node.fields.map(Node(it))
			}
			GlobalDecl {
				return node.fields.map(Node(it))
			}
			ConstDecl {
				return node.fields.map(Node(it))
			}
			EnumDecl {
				return node.fields.map(Node(it))
			}
			FnDecl {
				if node.is_method {
					children << Node(node.receiver)
				}
				children << node.params.map(Node(it))
				children << node.stmts.map(Node(it))
			}
			else {}
		}
	} else if node is ScopeObject {
		match node {
			GlobalField, ConstField, Var { children << node.expr }
		}
	} else {
		match node {
			GlobalField, ConstField, EnumField, StructInitField {
				children << node.expr
			}
			SelectBranch {
				children << node.stmt
				children << node.stmts.map(Node(it))
			}
			IfBranch, File {
				return node.stmts.map(Node(it))
			}
			MatchBranch {
				children << node.stmts.map(Node(it))
				children << node.exprs.map(Node(it))
			}
			else {}
		}
	}
	return children
}

// TODO: remove this fugly hack :-|
// fe2ex/1 and ex2fe/1 are used to convert back and forth from
// table.FExpr to ast.Expr , which in turn is needed to break
// a dependency cycle between v.ast and v.table, for the single
// field table.Field.default_expr, which should be ast.Expr
pub fn fe2ex(x table.FExpr) Expr {
	res := Expr{}
	unsafe { C.memcpy(&res, &x, sizeof(Expr)) }
	return res
}

pub fn ex2fe(x Expr) table.FExpr {
	res := table.FExpr{}
	unsafe { C.memcpy(&res, &x, sizeof(table.FExpr)) }
	return res
}

// experimental ast.Table
pub struct Table {
	// pub mut:
	// main_fn_decl_node FnDecl
}

// helper for dealing with `m[k1][k2][k3][k3] = value`
pub fn (mut lx IndexExpr) recursive_mapset_is_setter(val bool) {
	lx.is_setter = val
	if mut lx.left is IndexExpr {
		if lx.left.is_map {
			lx.left.recursive_mapset_is_setter(val)
		}
	}
}
