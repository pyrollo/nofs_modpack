# Items by type

## Common to all

- **id**: Unique (in the form) name of the widget. Default: key of the list element.
- **type**: Type of widget

## Container

- **layout**: Layout of the container, ''vbox'' vertical box (default), ''hbox'', horizontal box

## Button

- **height**, **width** : Size of the button
- **label**: Label displayed on the button
- **image**: Image displayed on the button
- **item**: Item displayed on the button

A button can't have both **image** and **item** attributes. In such case **item** attribute is ignored.

- **exit**: If true, the button will exit on click. Doesn't work if button has an **item** attribute. **close_form** can be used for such buttons.

## Field

- **height**, **width** : Size of the field
- **default**: Default value for this field if empty
- **hidden**: If true, the field will not display text (password field)

## Label

- **height**, **width** : Size of the label. Actually for placement purpose, the text is not bound by this size
- **label**: Text displayed
- **direction**: ''horizontal'' (default) or ''vertical'' text direction




- **context**: Context var ?
- **meta**: Associated metadata if <-- Voir comment on peut faire ça; associer un noeud au contexte ?



| Formspec element | nofs widget | Status |
| --- | --- |
| size[W,H] | Form level | Done |
| position[X,Y] | Form level | Not started |
| anchor[X,Y] | Form level | Not started |
| no_prepend[] | Form level | Not started |
| container[X,Y] | | Useless |
| container_end[] | | Useless |
| list[invloc;listname;X,Y;W,H;] | inventory | Done |
| list[invloc;listname;X,Y;W,H;index] | inventory | Not started |
| listring[invloc;listname] | inventory | Done |
| listring[] | ? | Not started |
| listcolors[bgcolor;bgcolorhover] | ? | Not started |
| listcolors[bgcolor;bgcolorhover;border] | ? | Not started |
| listcolors[bgcolor;bgcolorhover;border;tooltip_bg;tooltip_fontcolor] | ? | Not started |
| tooltip[id;text;bgcolor;fontcolor] | ? | Not started |
| tooltip[X,Y;W,H;text;bgcolor;fontcolor] | ? | Not started |
| image[X,Y;W,H;texture] | ? | Not started |
| item_image[X,Y;W,H;itemname] | ? | Not started |
| bgcolor[color;fullscreen] | Form level | Not started |
| background[X,Y;W,H;texture] | Form level | Not started |
| background[X,Y;W,H;texture;auto_clip] | Form level | Not started |
| pwdfield[X,Y;W,H;name;label] | field | Done |
| field[X,Y;W,H;name;label;default] | field | Done |
| field[name;label;default] | field | Done |
| field_close_on_enter[name;close_on_enter] | field | Not started |
| textarea[X,Y;W,H;name;label;default] | ? | Not started |
| label[X,Y;label] | label | Done |
| vertlabel[X,Y;label] | label | Done |
| button[X,Y;W,H;name;label] | button | Done |
| image_button[X,Y;W,H;image;name;label] | button | Done |
| image_button[X,Y;W,H;image;name;label;noclip;drawborder;pressedimage] | button | Not started |
| item_image_button[X,Y;W,H;item name;name;label] | button | Done |
| button_exit[X,Y;W,H;name;label] | button | Done |
| image_button_exit[X,Y;W,H;image;name;label] | button | Done |
| textlist[X,Y;W,H;name;listelem 1,listelem 2,...,listelem n] | ? | Not started |
| tabheader[X,Y;name;caption 1,caption 2,...,caption n;current_tab;transparent;draw_border] | ? | Not started |
| textlist[X,Y;W,H;name;listelem 1,listelem 2,...,listelem n;selected idx;transparent] | ? | Not started |
| box[X,Y;W,H;color] | vbox/hbox | Not started |
| checkbox[X,Y;label] | checkbox | Done |
| dropdown[X,Y;W;name;item 1,item 2, ...,item n;selected idx] | ? | Not started |
| scrollbar[X,Y;W,H;orientation;name;value] | ? | Not started |
| table[X,Y;W,H;name;cell 1,cell 2,...,cell n;selected idx] | ? | Not started |
| tablecolumns[type 1,opt 1a,opt 1b,...;type 2,opt 2a,opt 2b;...] | ? Not started |
