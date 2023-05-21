# typst-autodoc

Automaticaly generate a documentation pdf for your library using java docstring format

```typst
/**
 * this will render as info
 * @param this as a parameter
 */
#let foo(this)= {}

#import "typst-autodoc.typ": main
#main("this.typ")
```
![example render](example.png)

Supported : `@param`, `@see`, `@version`, `@returns`, more if needed

example.pdf coincidentally also documents the (few) functions of the library itself