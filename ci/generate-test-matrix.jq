
def xcontains($element):
	. as $input
	| $element | to_entries | map($input[.key] == .value) | all
;

def unseen:
	[ (.singles | length), (.pairs | length) ]
;

def flatten_objects:
	if ([ .[][] | select(type == "array" or type == "object") ] | length) >= 1 then
		[
		.[] | [ to_entries[] | select((.value | type) == "object" or (.value | type) == "array") ][0] as $i
			| if ($i.value | type) == "object"
				then . + ( $i.value | keys[] | { ($i.key): . } + $i.value[.] )
				elif ($i.value | type) == "array"
				then . + { ($i.key): ($i.value[]) }
			end
		] | flatten_objects
	end
;

.["virt-install"]
| if $ARGS.named["reverse-exclude"] then
	.[".include"] = ( .[".exclude"] | map(select(getpath([".no-exclude-test"]) | not)) )
	| .[".exclude"] = ( .[".exclude"] | map(select(getpath([".no-exclude-test"]))) )
	end
| ( .[".include"] // [] | flatten_objects ) as $include
| ( [ .[".exclude"] // [] | flatten_objects[] | [ paths[] | select(startswith(".")) ] as $p | delpaths([$p[] | [.]]) ] ) as $exclude
| ( .[".count"] // ([ .[] | select(arrays), select(objects) | length ] | max * 2) ) as $count
| ( .[".match-set"] // [] ) as $matchset

| (to_entries | map(.key | select(startswith(".") | not))[0]) as $first
| ( [ { $first: .[ $first ] } ] | flatten_objects ) as $first_data
| [ to_entries
	| map(select(.key | (startswith(".") or .== $first) | not))
	| from_entries
	+ $first_data[]
]
| flatten_objects

| if $ARGS.named["reverse-exclude"] then map(.["second-machine"] = "(none)") end

| [ .[] | reduce $matchset[] as $ms (.; if xcontains($ms.match) then $ms.set + . end) ]
| flatten_objects

| if $include | length > 0 then
	[ .[] as $in | first($include[] | select(
		[ paths[] | select(startswith(".")) ] as $p | delpaths([$p[] | [.]]) as $i
		| $in | xcontains($i)))
		| $in + ( with_entries( if .key | startswith(".") then .key = .key[1:] end ) ) ]
	end
| map(select(. as $in | any($exclude[] as $e | $in | xcontains($e)) | not))

| [ .[]
	| ( [ to_entries[] | [.] | from_entries ] ) as $singles
	| {
		r: .,
		singles: $singles,
		pairs: [ $singles | range(0; length) as $i | range($i + 1; length) as $j | [.[$i], .[$j]] ]
	}
]

| ( $ARGS.named.seed // 42 | tonumber ) as $seed
| [ limit($count + 1; $seed % 2147483646 + 1 | recurse(. * 48271 % 2147483647)) ][1:] as $random
| reduce range([ $count, length ] | min) as $n (.;
	( if $n == 0 then [ range(length) ]
		else ( .[$n:] | map(unseen) | max ) as $max
			| [ range($n; length) as $i | select((.[$i] | unseen) == $max) | $i ]
		end ) as $list

	| $list[ $random[$n] % ($list | length) ] as $selected_index
	| .[$selected_index] as $selected
	| .[$selected_index] = .[$n]
	| .[$n] = $selected

	| reduce range($n + 1; length) as $i (.;
		.[$i].singles -= $selected.singles
		| .[$i].pairs -= $selected.pairs
	)
)
| .[:$count]
| map(.r)

# order keys in object for better workflow run display
| map(. as $in | pick(.name, .["arch-display"], .arch, .["runs-on"], .boot, .["second-machine"]) + $in)

| sort_by(.name, .["arch-display"], .arch, .["runs-on"], .boot, .["second-machine"])

