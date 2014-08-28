# Copyright (c) 2014, Tobias Pollmann
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

use strict;
use LWP::UserAgent;
use WWW::YouTube::Download;
use HTML::Entities;

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = "0";

sub get_infos {
	my $id = shift;
	my $ua = LWP::UserAgent->new(timeout => 20, max_size => 41586);
	my $yt = WWW::YouTube::Download->new;
	my ($length, $title) = "";
	my $response = $ua->get("https://youtube.com/watch?v=".$id);
	if($response->decoded_content =~ m{"length_seconds": (\d{1,4}), }) {
		$length = $1;
		if($response->decoded_content =~ m{<title>(.*?)</title>}) {
			$title = decode_entities($1);
			$title =~ s/ - YouTube$//;
		}   
	} else {
		next;
	}   
	print "#EXTINF:$length,$title\n" if($title ne "" && $length ne "");
	print $yt->get_video_url($_) . "\n";
}

my @urls = (join(" ", @ARGV) =~ m/(https?:\/\/(?:youtu\.be\/|(?:[a-z]{2,3}\.)?youtube\.com\/watch(?:\?|#\!)v=)[\w-]{11}\S*)/g);

if(scalar @urls < 1) {
	print "Usage: $0 <url1 url2 url3...>\n";
	exit(0);
}

print "#EXTM3U\n";
my $ua = LWP::UserAgent->new(timeout => 20);
foreach (@urls) {
	get_infos(WWW::YouTube::Download->new->video_id($_)) if($_ !~ m/list=/);
	get_infos($_) foreach ($ua->get($_)->decoded_content  =~ m/href="\/watch\?v=(.\S+?)&amp;\S+"/g);
}
