USING: accessors help.markup help.syntax ui.gadgets.buttons
ui.gadgets.editors ui.frp.gadgets models ui.gadgets ;
IN: ui.frp.gadgets

HELP: <frp-button>
{ $values { "gadget" "the button's label" } { "button" button } }
{ $description "Creates an button whose signal updates on clicks.  " } ;

HELP: <frp-border-button>
{ $values { "text" "the button's label" } { "button" button } }
{ $description "Creates an button whose signal updates on clicks.  " } ;

HELP: <frp-table>
{ $values { "model" "values the table is to display" } { "table" frp-table } }
{ $description "Creates an " { $link frp-table } } ;

HELP: <frp-table*>
{ $values { "table" frp-table } }
{ $description "Creates an " { $link frp-table } " with no initial values to display" } ;

HELP: <frp-list>
{ $values { "column-model" "values the table is to display" } { "table" frp-table } }
{ $description "Creates an " { $link frp-table } " with a val-quot that renders each element as its own row" } ;

HELP: <frp-list*>
{ $values { "table" frp-table } }
{ $description "Creates an frp-list with no initial values to display" } ;

HELP: indexed
{ $values { "table" frp-table } }
{ $description "Sets the output model of an frp-table to the selected-index, rather than the selected-value" } ;

HELP: <frp-field>
{ $values { "model" model } { "gadget" model-field } }
{ $description "Creates a field with an initial value" } ;

HELP: <frp-field*>
{ $values { "field" model-field } }
{ $description "Creates a field with an empty initial value" } ;

HELP: <empty-field>
{ $values { "model" model } { "field" model-field } }
{ $description "Creates a field with an empty initial value that switches to another signal on its update" } ;

HELP: <frp-editor>
{ $values { "model" model } { "gadget" model-field } }
{ $description "Creates an editor with an initial value" } ;

HELP: <frp-editor*>
{ $values { "editor" "an editor" } }
{ $description "Creates a editor with an empty initial value" } ;

HELP: <empty-editor>
{ $values { "model" model } { "editor" "an editor" } }
{ $description "Creates a field with an empty initial value that switches to another signal on its update" } ;

HELP: <frp-action-field>
{ $values { "field" action-field } }
{ $description "Field that updates its model with its contents when the user hits the return key" } ;

HELP: IMAGE-BUTTON:
{ $syntax "IMAGE-BUTTON: filename" }
{ $description "Creates a button using a tiff image named as specified found in the icons subdirectory of the vocabulary path" } ;

HELP: output-model
{ $values { "gadget" gadget } { "model" model } }
{ $description "Returns the model a gadget uses for output. Often the same as " { $link model>> } } ;