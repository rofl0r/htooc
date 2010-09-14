#!/usr/bin/env perl
 
# convert C or D (suggested, since "preprocessed") headerfile to ooc
# author: rofl0r
#
# why not use babbisch ? well i dont want to use python and figure out 
# how its package management system works.

use strict;
use warnings;
#use re 'debugcolor';

sub converttype {
	my ($type) = @_;
	$type =~ s/uint/UInt/;
	$type =~ s/int/Int/;
	$type =~ s/char/Char/;
	$type =~ s/void/Void/;
	$type =~ s/Void\*/Pointer/;
	$type =~ s/ushort/UShort/;
	$type =~ s/short/Short/;
	$type =~ s/size_t/SizeT/;
	$type =~ s/ssize_t/SSizeT/;
	$type =~ s/ptrdiff_t/SSizeT/;
	$type =~ s/bool/Bool/;			
	$type =~ s/ubyte/Octet/;		
	$type =~ s/Char\*/CString/;		
	
	return $type;
}

sub trim{
   my $string = shift;
   $string =~ s/^\s+|\s+$//g;
   return $string;
}

sub myjoin {
	my @a = @_;
	my $res = "";
	foreach my $char(@a) {
		$res .= $char if($char);
	}
	return $res
}

sub fixpointers {
	my $string = shift;
	$string =~ s/(\w+)\s+\*\s*/$1* /g;
	return $string;
}

sub check_all_upper {
	$_ = shift;
	my @a = split //;
	foreach (@a) {
		return 0 if /^[a-z]/;
	}
	return 1;
}

sub ooccase {
	my $string = shift;
	return ($string, "") if check_all_upper($string);
	my @a = split(//, $string);
	my $lastChar = 0;
	my $makeBig = 0;
	my @del = ();
	for(my $i=0;$i<@a;$i++) {
		if($lastChar && $a[$i] eq "_") {
			push @del, $i;
			$lastChar = 0;
			$makeBig = 1;
		} else {
			if ($makeBig) {
				$a[$i] = uc($a[$i]);
				$makeBig = 0;
			}
			$lastChar = 1
		}
	}
	foreach my $item(@del) {
		delete $a[$item];
	}
	my $new = myjoin(@a);
	return ($new, "(" . $string . ")") if ($new ne $string);
	return ($string, "");
}

#exit check_all_upper("SOME_COaNST_NAME");

while(<>){
	chomp;
	$_=fixpointers($_);
	if (/^\s*\/\//) {
		#skipping comments.
		print("$_\n");
	} elsif (/^\s*(\w+\**)\s+(\w*)\s*\(([\w|\*| |,|\.]*)\)\s*;/) {
		#searching function declararions
		my $return = converttype($1);
		#no need to declare void return type in ooc
		if($return eq "Void") {
			$return = ""
		} else {
			$return = "-> " . $return
		}
		my ($funcname, $externname) = ooccase($2);

		my $args = $3;
		my $args_braced = "";
		if($args) {
			$args_braced = "(";
			my @arga = split /,/, $args;
			my $counter = 0;
			foreach my $item(@arga) {
				my $expr = trim($item);
				if ($expr =~ / /) {
					my @exprel = split / /, $expr;
					$expr = $exprel[1] . ": " . converttype($exprel[0])
				} else {
					$expr = converttype($expr);
				}
				$args_braced .= $expr;
				$args_braced .= ", " if($counter != @arga -1);
				$counter++;
			}
			$args_braced .= ")";
			$args_braced = "" if($args_braced eq "(Void)");
		}
		print("$funcname: extern$externname func$args_braced $return\n");
	} elsif (/^\s*const\s+(\w+\**)\s+(\w+)\s*=\s*.+?;/) { 
		#searching const's
		my $type = converttype($1);
		my ($name, $externname) = ooccase($2);
		print("$name: extern$externname $type\n");
	} elsif (/^\s*(alias|typedef)\s+?(\w+\**)\s+?(\w+)\s*;/) { 
		#searching simple typedef. we dont cover function pointers and arrays.
		my $type = converttype($2);
		my $name = $3;
		print("$name: cover from $type\n");
	} else {
		#not handled
		print("// $_\n");
	}
}