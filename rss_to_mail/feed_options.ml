(** Per feed options *)

type t = {
	refresh		: [ `Every of float | `At of int * int ];
	(** Update interval, Every in hour or At a specific time in the day *)
	title		: string option; (** Override the feed's title *)
	label		: string option; (** Appended to the content *)
	no_content	: bool; (** If the content should be removed *)
	filter		: (Str.regexp * bool) list; (** Filter entries by regex
		The boolean is the expected result of [string_match] *)
}

let make ?(refresh=`Every 6.) ?title ?label ?(no_content=false)
	?(filter=[]) () =
	{ refresh; title; label; no_content; filter }
