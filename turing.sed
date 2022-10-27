#!/usr/bin/sed -nrf
#Because sed can take the standard input only, we have to input the TM design and tape both by the standard input.
#For example:
#command : { cat examples/prime-list.rule; echo TAPE 1 1 2 1 1 2 2; } | ./turing.sed
#Get all the prime numbers not more than 100

s/#.*|^[ \t]+|[ \t]+$//g
/^$/d
s/[ \t]+/ /g

#number of characters
/^[0-9]+ +([0-9]+) *$/ {
	s//\1/

	:each_char
	/^1($| )/ b finish_all_chars
	s/^[^ ]+/& &/
	/^[0-9]*([1-9]) .*$/b minus1_direct
	s/^[0-9]+/&;/
	:0minus1
	s/0;/;9/
	t 0minus1
	/^[0-9]*([2-9];).*$/b minus1_direct
	s/1;/0/
	s/^0+//
	t each_char
	:minus1_direct
	h
	s//\1/
	y/123456789/012345678/
	G
	s/(.)(.?)\n([0-9]*)[1-9]\2/\3\1/
	t each_char

	:finish_all_chars
	h
	d
}

#TAPE INIT
/^TAPE\>/ {
	:get_all_tape
	$! {
		N
		b get_all_tape
	}
	s/\n/ /g
	s/[ \t]+/ /g
	s/ $//
	s/^[^ ]+ /0\n/
	/^0\n[0-9]+/!s/^0\n/&0/
	s/(^0\n)([0-9]+)/\1,\2/
	x
	s/^[^\n]*\n//
	x
	G
	t run
	
	#RUN
	:run
	/^[12]\n/ {
		/^1/b accept
		b reject
	}
	s/^([^\n]+)\n(.*,)([0-9]+\>)((.*\n)\1 \3 ([^ ]+) ([^ ]+) ([01]))/\8\6\n\2\7\4/
	t next
	b reject
	:next
	/^0([^ \n]+)\n/ {
		/^0([^ \n]+\n)(.*),([0-9]+) ([0-9]+)\>/ {
			s//\1\2\3 ,\4/
			t run
		}
		s/^0([^ \n]+\n)(.*),([0-9]+)/\1\2\3 ,0/
		t run
	}
	s/^1([^ \n]+\n)(.*)(\<[0-9]+) ,([0-9]+\>)/\1\2,\3 \4/
	t run
	b error 
	:accept
	s/^[^\n]+\n([^\n]*).*/ACCEPT\nTAPE:\n\1/
	b quit
	:reject
	s/^[^\n]+\n([^\n]*).*/REJECT\nTAPE:\n\1/
	b quit
	:error
	s/.*/ERROR/p
	q
	:quit
	s/( 0)+$//
	s/ /\t/g
	s/,([0-9]+)/[\1]/
	s/([^\t]+\t){16}/&\n/g
	s/\n$//
	p
	q
}

#Rules
/^(([^ ])+ +){4}([^ ])+ *$/ {
	s/ +/ /g
	s/ *$//
	s/[rR].*/0/
	s/[lL].*/1/
	s/^([^ ]+)( [^ ]+ )- /\1\2\1 /
	/^[^ ]+ (-|\*) / {
		G
		s/^([^\n]*\n[^\n]*).*/\1/
		/^[^ ]+ \*/s/\n/&0 /
		:expand_rules
		s/^([^ ]+ )(.)([^\n]*)\n ?([0-9]+)(.*)$/\1\2\3\n\5\n\1\4\3/
		s/(\n[^ ]+ )([^ ]+)( [^ ]+ )-( [^\n]*)$/\1\2\3\2\4/
		t expand_rules
		s/[^\n]*\n[^\n]*\n//
		H
		d
	}
	
	s/^([^ ]+ )([^ ]+)( [^ ]+ )- /\1\2\3\2 /
	H
	d
}
