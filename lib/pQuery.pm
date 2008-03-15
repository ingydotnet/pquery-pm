# pQuery - A Perl version of jQuery.

package pQuery;
use strict;
use warnings;
use 5.006001;
use pQuery::DOM;

use base 'Exporter';

our $VERSION = '0.04';

our @EXPORT = qw(pQuery PQUERY);

our $document;

my $my = {};
my $lwp_user_agent;
my $quickExpr = qr/^([^<]*<(.|\s)+>[^>]*)$|^#(\w+)$/;
my $isSimple = qr/^.[^:#\[\.]*$/;
my $dom_element_class = 'pQuery::DOM';

sub pQuery {
    return 'pQuery'->new(@_);
}

sub PQUERY {
    return 'PQUERY'->new(@_);
}

################################################################################
# Playing around stuffs
################################################################################
sub url {
    my $this = shift;
    return $my->{$this}{url}
        if $my->{$this}{url};
    while ($this = $my->{$this}{prevObject}) {
        return $my->{$this}{url}
            if $my->{$this}{url};
    }
    return;
}

################################################################################
# Truly ported from jQuery stuff
################################################################################
sub new {
    my $class = shift;
    my $this = bless [], $class;
    $my->{$this} = {};
    return $this->_init(@_);
}

sub _init {
    my ($this, $selector, $context) = @_;

    $selector ||= $document or return $this;

    if (ref($selector) eq $dom_element_class) {
        @$this = $selector;
        return $this;
    }
    elsif (not ref($selector)) {
        my $match = ($selector =~ $quickExpr);

        if ($match and ($1 or not $context)) {
            if ($1) {
                $selector = [pQuery::DOM->fromHTML($1)];
#                 $selector = $this->_clean([$1], $context);
            }
            else {
                my $elem = $document->getElementById($3);
                if ($elem) {
                    @$this = $elem;
                    return $this;
                }
                else {
                    $selector = [];
                }
            }
        }
        else {
            if ($selector =~ /^\s*(https?|file):/) {
                $my->{$this}{url} = $selector;
                return $document = $this->_new_from_url($selector);
            }
            elsif ($selector =~ /^\S+\.html?$/) {
                $my->{$this}{file} = $selector;
                open FILE, $selector;
                my $html = do {local $/; <FILE>};
                close FILE;
                $selector = [pQuery::DOM->fromHTML($html)];
            }
            else {
                return pQuery($context)->find($selector);
            }
        }
    }
    @$this = (ref($selector) eq 'ARRAY' or ref($selector) eq 'pQuery')
        ? @$selector
        : $selector;
    return $this;
}

sub pquery { return $VERSION }

sub size { return $#{$_[0]} + 1 }
sub length { return $#{$_[0]} + 1 }

sub get {
    my $this = shift;

    # Get could be for Ajax URL or Object Member
    return $this->_web_get(@_)
        if @_ and $_[0] !~ /^\d+$/;

    return @_
        ? $this->[$_[0]]
        : wantarray ? (@$this) : $this->[0];
}

sub pushStack {
    my ($this, $elems) = @_;
    my $ret = pQuery($elems);
    $ret->_prevObject($this);
    return $ret;
}

sub _prevObject {
    my $this = shift;
    return @_
        ? ($my->{$this}{prevObject} = $_[0])
        : $my->{$this}{prevObject};
}

# Not needed in Perl
# sub _setArray {
#     my ($this, $elems) = @_;
#     @$this = @$elems;
#     return $this;
# }

sub each {
    my ($this, $sub) = @_;
    my $i = 0;
    &$sub($i++) for @$this;
    return $this;
}

sub index {
    my ($this, $elem) = @_;
    my $ret = -1;
    $this->each(sub {
        $ret = shift
            if (ref($_) && ref($elem)) ? ($_ == $elem) : ($_ eq $elem);
    });
    return $ret;
}

sub attr { # (name, value, type)
    # TODO - Get/set a named attribute
}

sub css { # (key, value)
    # TODO - Get/set a css attribute
}

# TODO/XXX Made up. Not ported yet.
sub text {
    # TODO - Get/set text value
    my $this = shift;
    my $text = '';

    $this->each(sub {
        _to_text($_, \$text);
    });

    $text =~ s/\s+/ /g;
    $text =~ s/\s$//;

    return $text;
}

sub wrapAll { # (html)
    # TODO - Wrap element with HTML
}

sub wrapInner { # (html)
    # TODO - Wrap sub elements with HTML
}

sub wrap { # (html)
    # TODO - Wrap current objects with HTML
}

sub append { # (@_)
    # TODO - Append arguments to current objects
}

sub prepend { # (@_)
    # TODO - Prepend arguments to current objects
}

sub before { # (@_)
    # TODO - Insert arguments before current objects
}

sub after { # (@_)
    # TODO - Insert arguments after current objects
}

sub end {
    my $this = shift;
    return $this->_prevObject || pQuery([]);
}

# XXX - Not really ported yet.
sub find {
    my $this = shift;
    my $selector = shift or return;
    my $elems = [];
    $this->each(sub {
        _find_elems($_, $selector, $elems);
    });
    return $this->pushStack($elems);
}

# sub find {
#     my ($this, $selector) = @_;
#     my $elems = pQuery::map($this, sub {



sub clone { # (events)
    # TODO - Not sure if we need this one.
}

sub filter { # (selector)
    # TODO - A kind of grep
}

sub not { # (selector)
    # TODO - An anti-grep??
}

sub add { # (selector)
    # TODO - Some kind of merge
}

sub is { # (selector)
    # TODO - One element matches the selector
}

sub hasClass {
    my ($this, $selector) = @_;
    $this.is(".$selector");
}

sub val { # (value)
    # TODO Get/set
}

# XXX - Not really ported yet.
sub html {
    my $this = shift;
    return unless @$this;
    if (@_) {
        for (@$this) {
            next unless ref($_);
            $_->innerHTML(@_);
        }
        return $this;
    }
    return $this->[0]->innerHTML(@_);
}

# Not a jQuery function.
sub toHtml {
    my $this = shift;
    return unless @$this;
    return $this->[0]->toHTML;
}

# TODO - Not tested
sub replaceWith { # (value)
    my ($this, $value) = @_;
    return $this->after($value)->remove;
}

# TODO - Not tested
sub eq {
    my ($this, $i) = @_;
    return $this->pushStack($this->[$i]);
}

sub slice { #(i, j)
    # TODO - Behave like JS slice()
}

sub map {
    my ($this, $callback) = @_;
    return $this->pushStack(__map($this, sub {
        my ($elem, $i) = @_;
        return $callback->($elem, $i, $elem);
    }));
}

# TODO - Not tested
sub andSelf {
    my $this = shift;
    return $this.add($this->prevObject);
}

sub data { # (key, value)
    # TODO - Not sure
}

sub removeData { # (key)
    # TODO - Not Sure
}

sub domManip {
    my ($this, $args, $table, $reverse, $callback) = @_;
    my $elems;
    return $this->each(sub {
        if (! defined $elems) {
            $elems = $args;
            @$elems = reverse @$elems
              if $reverse;
        }
        pQuery::each($elems, sub {
            $callback->($this, $_);
        });
    });
}

################################################################################
# "Class" methods
################################################################################
# sub noConflict {}
# sub isFunction {}
# sub isXMLdoc {}
# sub globalEval {}
# sub nodeName {}
# sub cache {}
# sub data {}
# sub removeData {}
# sub each {}
# sub prop {}
# sub className {}
# sub swap {}
# sub css {}
# sub curCSS {}
# sub clean {}
# sub attr {}
# sub trim {}
# sub makeArray {}
# sub inArray {}
# sub merge {}
# sub unique {}
# sub grep {}
# sub map {}
# sub unique {}

################################################################################
# Selector functions
################################################################################


################################################################################
# Helper functions (not methods)
################################################################################
sub _new_from_url {
    my $this = shift;
    my $url = shift;
    my $response = $this->get($url);
    return $this
        unless $response->is_success;
    @$this = pQuery::DOM->fromHTML($response->content);
    return $this;
}

sub _web_get {
    my $this = shift;
    my $url = shift;
    require LWP::UserAgent;
    $lwp_user_agent ||= LWP::UserAgent->new;

    my $request = HTTP::Request->new(GET => $url);
    my $response = $lwp_user_agent->request($request);
    return $response;
}

sub _to_text {
    my ($elem, $text) = @_;
    if (ref $elem) {
        for my $child (@{$elem->{_content}}) {
            _to_text($child, $text);
        }
    }
    else {
        $$text .= $elem;
    }
}

sub _find_elems {
    my ($elem, $selector, $elems) = @_;
    return unless ref $elem;

    if ($selector =~ /^\w+$/) {
        if ($elem->{_tag} eq $selector) {
            push @$elems, $elem;
        }
    }

    for my $child (@{$elem->{_content}}) {
        _find_elems($child, $selector, $elems);
    }
}

################################################################################
# THE AMAZING PQUERY
################################################################################
package PQUERY;

sub new {
    my $class = shift;
    my $this = bless [], $class;
    @$this = map 'pQuery'->new($_), @_;
    return $this;
}

sub AUTOLOAD {
    (my $method = $PQUERY::AUTOLOAD) =~ s/.*:://;
    my $this = shift;
    my @args = @_;
    $this->EACH(sub {
        my $i = shift;
        $this->[$i] = $_->$method(@args);
    });
    return $this;
}

sub EACH {
    my ($this, $sub) = @_;
    my $index = 0;
    &$sub($index++) for @$this;
    return $this;
}

sub DESTROY {}

1;

=head1 NAME

pQuery - Perl Port of jQuery.js

=head1 SYNOPSIS

    use pQuery;

    pQuery("http://google.com/search?q=pquery")
        ->find("h2")
        ->each(sub {
            my $i = shift;
            print $i + 1, ") ", pQuery($_)->text, "\n";
        });

=head1 DESCRIPTION

pQuery is a pragmatic attempt to port the jQuery JavaScript framework to
Perl. It is pragmatic in the sense that it switches certain JavaScript
idioms for Perl ones, in order to make the use of it concise. A primary
goal of jQuery is to "Find things and do things, concisely". pQuery has
the same goal.

pQuery exports a single function called C<pQuery>. (Actually, it also
exports the special C<PQUERY> function. Read below.) This function acts
a constructor and does different things depending on the arguments you
give it. This is discussed in the L<CONSTRUCTORS> section below.

A pQuery object acts like an array reference (because, in fact, it is).
Typically it is an array of pQuery::DOM elements, but it can be an array
of anything.

pQuery::DOM is roughly an attempt to duplicate JavaScript's DOM in
Perl. It subclasses HTML::TreeBuilder/HTML::Element so there are a
few differences to be aware of. See the L<pQuery::DOM> documentation
for details.

Like jQuery, pQuery methods return a pQuery object; either the
original object or a new derived object. All pQuery L<METHODS> are
described below.

=head1 THE ROYAL PQUERY

The power of jQuery is that single method calls can apply to many DOM
objects. pQuery does the exact same thing but can take this one step
further. A single PQUERY object can contain several DOMs!

Consider this example:

    > perl -MpQuery -le 'PQUERY(\
        map "http://search.cpan.org/~$_/", qw(ingy gugod miyagawa))\
        ->find("table")->eq(1)->find("tr")\
        ->EACH(sub{\
            printf("%40s - %s Perl distributions\n", $_->url, $_->length - 1)\
        })'
               http://search.cpan.org/~ingy/ - 88 Perl distributions
              http://search.cpan.org/~gugod/ - 86 Perl distributions
           http://search.cpan.org/~miyagawa/ - 138 Perl distributions

The power lies in C<PQUERY>, a special constructor that creates a
wrapper object for many pQuery objects, and applies all methods called
on it to all the pQuery objects it contains.

=head1 CONSTRUCTORS

The pQuery constructor is an exported function called C<pQuery>. It does
different things depending on the arguments you pass it.

=head2 URL

If you pass pQuery a URL, it will attempt to get the page and use its
HTML to create a pQuery::DOM object. The pQuery object will contain the
top level pQuery::DOM object.

    pQuery("http://google.com");

It will also set the global variable C<$pQuery::document> to the
resulting DOM object. Future calls to pQuery methods will use this
document if none other is supplied.

=head2 HTML

If you already have an HTML string, pass it to pQuery and it will create
a pQuery::DOM object. The pQuery object will contain the top level
pQuery::DOM object.

    pQuery("<p>Hello <b>world</b>.</p>");

=head2 FILE

If you pass pQuery a string that ends with .html and contains no
whitespace, pQuery will assume it is the name of a file containing html
and will read the contents and parse the HTML into a new DOM.

    pQuery("my/webpage.html");

=head2 Selector String

You can create a pQuery object with a selector string just like in
jQuery. The problem is that Perl doesn't have a global document object
lying around like JavaScript does.

One thing you can do is set the global variable, C<$pQuery::document>,
to a pQuery::DOM document. This will be used by future selectors.

Another thing you can do is pass the document to select on as the second
parameter. (jQuery also has this second, context parameter).

    pQuery("table.mygrid > td:eq(7)", $dom);

=head2 pQuery Object

You can create a new pQuery object from another pQuery object. The new
object will be a shallow copy.

    my $pquery2 = pQuery($pquery1);

=head2 Array Reference

You can create a pQuery object as an array of anything you want; not
just pQuery::DOM elements. This can be useful to use the C<each> method to
iterate over the array.

    pQuery(\ @some_array);

=head2 No Arguments

Calling pQuery with no arguments will return a pQuery object that is
just an empty array reference. This is useful for using it to call class
methods that don't need a DOM object.

    my $html = pQuery->get("http://google.com")->content;

=head2 PQUERY(@list_of_pQuery_constructor_args)

The PQUERY constructor takes a list of any of the above pQuery forms and
creates a PQUERY object with one pQuery object per argument.

=head1 METHODS

This is a reference of all the methods you can call on a pQuery object. They
are almost entirely ported from jQuery.

=head2 pquery()

Returns the version number of the pQuery module.

=size()

Returns the number of elements in the pQuery object.

=length()

Also returns the number of elements in the pQuery object.

=head2 each($sub)

This method takes a subroutine reference and calls the subroutine once
for each member of the pQuery object that called C<each>. When the
subroutine is called it is passed an integer count starting at 0 at
incremented once for each call. It is also passed the current member of
the pQuery object in C<$_>.

    pQuery("td", $dom)->each(sub {
        my $i = shift;
        print $i, " => ", pQuery($_)->text(), "\n";
    });

The C<each> method returns the pQuery object that called it.

=head2 EACH($sub)

This method can only be called on PQUERY objects. The sub is called once
for every pQuery object within the PQUERY object. If you call C<each()>
on a PQUERY object, it iterates on all the DOM objects of each pQuery
object (as you would expect).

=head2 find($selector)

This method will search all the pQuery::DOM elements of the its caller for
all sub elements that match the selector string. It will return a new
pQuery object containing all the elements found.

    my $pquery2 = $pquery1->find("h1,h2,h3");

=head2 html() html($html)

This method is akin to the famous JavaScript/DOM function C<innerHTML>.

If called with no arguments, this will return the the B<inner> HTML
string of the B<first> DOM element in the pQuery object.

If called with an HTML string argument, this will set the inner HTML of all
the DOM elements in the pQuery object.

=head2 toHtml()

This extremely handy method is not ported from jQuery. Maybe jQuery will
port it back some day. :)

This function takes no arguments, and returns the B<outer> HTML of the first
DOM object in the pQuery object. Outer HTML means the HTML of the current
object and its inner HTML.

For example:

    pQuery('<p>I <b>like</b> pie</p>').HTML();

returns:

    <p>I <b>like</b> pie</p>

while:

    pQuery('<p>I <b>like</b> pie</p>').html();

returns:

    I <b>like</b> pie

=head2 end()

Revert the most recent 'destructive' operation, changing the set of
matched elements to its previous state (right before the destructive
operation). This method is useful for getting back to a prior context
when chaining pQuery methods.

    pQuery("table", $dom)     # Select all the tables
        ->find("td")          # Select all the tds
        ->each(sub { ... })   # Do something with the tds
        ->end()               # Go back to the tables selection
        ->each(sub { ... });  # Do something with the tables

=head2 get($index) get($url)

If this method is passed an integer, it will return that specific
element from the array of elements in the pQuery object.

Givn a URL, this method will fetch the HTML content of the URL and
return a HTML::Response object.

    my $html = pQuery.get("http://google.com")->content;

=head2 index($elem)

This method returns the index number of its argument if the elem is in the
current pQuery object. Otherwise it returns -1.

=head1 UNDER CONSTRUCTION

This module is still being written. The documented methods all work as
documented (but may not be completed ports of their jQuery
counterparts yet).

The selector syntax is still very limited. (Single tags, IDs and classes
only).

Version 0.02 added the pQuery::DOM class which is a huge improvement, and
should facilitate making the rest of the porting easy.

But there is still much more code to port. Stay tuned...

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2008. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
