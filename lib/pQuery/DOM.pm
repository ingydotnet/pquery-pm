package pQuery::DOM;
use strict;
use warnings;

use base 'HTML::TreeBuilder';
use base 'HTML::Element';

# This is a copy of HTML::TreeBuilder::new. Sadly. TreeBuilder should be
# easier to subclass. The only change is s/HTML::Element/pQuery::DOM/g.
sub _builder { # constructor!
    my $class = shift;
    $class = ref($class) || $class;

    my $self = pQuery::DOM->new('html');  # Initialize HTML::Element part
    {
        # A hack for certain strange versions of Parser:
        my $other_self = HTML::Parser->new();
        %$self = (%$self, %$other_self);              # copy fields
        # Yes, multiple inheritance is messy.  Kids, don't try this at home.
        bless $other_self, "HTML::TreeBuilder::_hideyhole";
        # whack it out of the HTML::Parser class, to avoid the destructor
    }

    # The root of the tree is special, as it has these funny attributes,
    # and gets reblessed into this class.

    # Initialize parser settings
    $self->{'_implicit_tags'}  = 1;
    $self->{'_implicit_body_p_tag'} = 0;
    # If true, trying to insert text, or any of %isPhraseMarkup right
    #  under 'body' will implicate a 'p'.  If false, will just go there.

    $self->{'_tighten'} = 1;
    # whether ignorable WS in this tree should be deleted

    $self->{'_implicit'} = 1;  # to delete, once we find a real open-"html" tag

    $self->{'_element_class'}      = 'pQuery::DOM';
    $self->{'_ignore_unknown'}     = 1;
    $self->{'_ignore_text'}        = 0;
    $self->{'_warn'}               = 0;
    $self->{'_no_space_compacting'}= 1;
    $self->{'_store_comments'}     = 0;
    $self->{'_store_declarations'} = 0;
    $self->{'_store_pis'}          = 0;
    $self->{'_p_strict'}           = 0;

    # Parse attributes passed in as arguments
    if(@_) {
        my %attr = @_;
        for (keys %attr) {
            $self->{"_$_"} = $attr{$_};
        }
    }

    # rebless to our class
    bless $self, $class;

    $self->{'_element_count'} = 1;
    # undocumented, informal, and maybe not exactly correct

    $self->{'_head'} = $self->insert_element('head',1);
    $self->{'_pos'} = undef; # pull it back up
    $self->{'_body'} = $self->insert_element('body',1);
    $self->{'_pos'} = undef; # pull it back up again
    $self->ignore_ignorable_whitespace(0);
    $self->store_comments(1);
    $self->no_space_compacting(1);

    return $self;
}

sub new {
    my $class = shift;
    $class = ref($class) || $class;

    my $tag   = shift;
    Carp::croak("No tagname") unless defined $tag and length $tag;
    Carp::croak "\"$tag\" isn't a good tag name!"
    if $tag =~ m/[<>\/\x00-\x20]/; # minimal sanity, certainly!
    my $self  = bless { _tag => scalar($class->_fold_case($tag)) }, $class;
    my($attr, $val);
    while (($attr, $val) = splice(@_, 0, 2)) {
        $val = $attr unless defined $val;
        $self->{$class->_fold_case($attr)} = $val;
    }
    if ($tag eq 'html') {
        $self->{'_pos'} = undef;
    }
    return $self;
}

################################################################################
# pQuery::DOM Class Methods
################################################################################
sub fromHTML {
    my ($class, $html) = @_;
    my $dom;
    if ($html =~ /^\s*<html.*?>.*<\/html>\s*\z/s) {
        $dom = $class->_builder->parse_content($html);
        return $dom;
    }
    $dom = $class->_builder->parse_content('<dummy>' . $html . '</dummy>');
    my @dom = map {
        if (ref($_)) {
            delete $_->{_parent};
        }
        $_;
    } @{$dom->{_body}{_content} || [$dom->{_content}[-1]]};
    return wantarray ? @dom : $dom[0];
}

sub createElement {
    my ($class, $tag) = @_;
    return unless $tag =~ /^\w+$/;
    return $class->fromHTML('<' . $tag . '>');
}

sub createComment {
    my ($class, $comment) = @_;
    return $class->fromHTML('<!--' . $comment . '-->');
}

################################################################################
# DOM Object Methods
################################################################################
sub toHTML {
    my $self = shift;

    my $html = '';

    _to_html($self, \$html);

    return $html;
}

sub innerHTML {
    my $self = shift;

    return if $self->{_tag} eq '~comment';

    if (@_) {
        $self->{_content} = [pQuery::DOM->fromHTML($_[0])];
        return $_[0];
    }

    my $html = '';

    my @list = @{$self->{_content} || []};
    for (@list) {
        _to_html($_, \$html);
    }

    return $html;
}

sub getElementsByTagName {
    my ($self, $tag) = @_;
    my $found = [];
    _find($self, $found, sub { $_->{_tag} eq $tag});
    return wantarray ? @$found : $found->[0];
}

sub getElementById {
    my ($self, $id) = @_;
    my $found = [];
    _find($self, $found, sub { $_->{id} and $_->{id} eq $id});
    return wantarray ? @$found : $found->[0];
}

sub nodeType {
    return $_[0]->{_tag} eq '~comment' ? 8 : 1;
}

sub nodeName {
    return '#comment' if $_[0]->{_tag} eq '~comment';
    return uc($_[0]->{_tag});
}

sub tagName {
    return '' if $_[0]->{_tag} eq '~comment';
    return $_[0]->nodeName;
}

sub nodeValue {
    my $self = shift;
    return $self->{text} if $self->{_tag} eq '~comment';
    return;
}

sub getAttribute {
    return $_[0]->{$_[1]};
}

sub setAttribute {
    $_[0]->{lc($_[1])} = $_[2];
    return;
}

sub removeAttribute {
    delete $_[0]->{lc($_[1])};
}

sub hasAttributes {
    my $self = shift;
    return 0 if $self->{_tag} eq '~comment';
    return scalar(grep /^[a-z0-9]/, keys %$self) ? 1 : 0;
}

sub className {
    if ($_[1]) {
        return $_[0]->setAttribute(class => $_[1]);
    }
    $_[0]->getAttribute("class");
}

sub parentNode {
    return $_[0]->{_parent};
}

sub childNodes {
    return @{$_[0]->{_content} || []};
}

sub firstChild {
    return unless $_[0]->{_content};
    return $_[0]->{_content}[0];
}

sub lastChild {
    return unless $_[0]->{_content};
    return $_[0]->{_content}[-1];
}

sub appendChild {
    my ($self, $elem) = @_;
    return unless defined $elem;
    my $content = $self->{_content} ||= [];
    push @$content, $elem;
    return $elem;
}

sub previousSibling {
    die "pQuery::DOM does not support the previousSibling method";
}

sub nextSibling {
    die "pQuery::DOM does not support the nextSibling method";
}

sub attributes {
    die "pQuery::DOM::attributes not yet implemented";
}

################################################################################
# Helper Functions
################################################################################
sub _to_html {
    my ($elem, $html) = @_;
    if (not ref $elem) {
        $$html .= $elem;
        return;
    }
    if ($elem->{_tag} eq '~comment') {
        $$html .= '<!--' . $elem->{text} . '-->';
        return;
    }
    $$html .= '<' . $elem->{_tag};
    $$html .= qq{ id="$elem->{id}"}
        if $elem->{id};
    $$html .= qq{ class="$elem->{class}"}
        if $elem->{class};
    for (sort keys %$elem) {
        next if /^(_|id$|class$)/i;
        $$html .= qq{ $_="$elem->{$_}"};
    }
   
    $$html .= '>';
    for my $child (@{$elem->{_content} || []}) {
        _to_html($child, $html);
    }
    $$html .= '</' . $elem->{_tag} . '>';
}

sub _find {
    my ($elem, $found, $test) = @_;
    $_ = $elem;
    if (&$test()) {
        push @$found, $_;
    }

    map _find($_, $found, $test), grep ref($_), @{$elem->{_content} || []};
}

1;

=head1 NAME

pQuery::DOM - A DOM Class for pQuery

=head1 SYNOPSIS

    my $dom = pQuery::DOM->fromHTML('<p>I <b>Like</b> Pie</p>';

=head1 DESCRIPTION

jQuery makes use of the browser's built in DOM. Indeed, most jQuery
objects are collections of DOM objects.

pQuery needs a DOM to represent its content. Since there is no standard
DOM class in Perl, pQuery implements its own.

=head1 DOM MODEL

It is important to note that pQuery::DOM is essentially a subclass of
HTML::TreeBuilder and HTML::Element. As such, text nodes are just
strings and therefore cannot have methods called on them.

This implies that the DOM methods previousSibling and nextSibling
wouldn't really work correctly. Therefore they are not implemented.

To deal with children, use the childNodes method which returns a list
of all the child nodes. Then you can use standard Perl idioms to
process them.

Note that all pQuery::DOM objects are either HTML Element nodes or HTML
Comment nodes.

=head1 METHODS

The names of (most of) the pQuery::DOM methods are the same as their
JavaScript counterparts. However only a subset of the JavaScript DOM is
actually implemented.

=head2 Class Methods

=over

=item fromHTML($html)

This is the main constructor method. It takes any HTML string and
returns the DOM object tree that represents that HTML.

=item createElement($tag)

Create a new HTML Element node with the specified tag. This node will be
empty and have no attributes.

=item createComment($text)

Create a new HTML Comment node with the given text value.

=back

=head2 Object Methods

=over

=item toHTML()

This method returns the HTML string that represents the DOM tree on
which it was invoked.

=item innerHTML() innerHTML($html)

If called with no arguments, this method returns the HTML string of the
DOM tree inside this node.

If called with an HTML argument, this method replaces the inner DOM tree
with the tree created from the HTML.

=item getElementById($id)

Returns a list of all the elements with the given id. Normally this
should be one or zero elements, since two nodes should not have the same
id in the same DOM.

=item getElementsByTagName($tag)

Returns a list of all elements in the tree that have the given tag name.

=item nodeType

Returns 1 if the node is an HTML Element and 8 if it is a comment node.
Never returns 3 (the type value of a text node) since text nodes in the
DOM are just strings.

=item nodeName

This method returns the name of the node, which is the uppercase
HTML tag name.

Returns '#comment' if the node is a comment node.

=item tagName

Returns the nodeName of the element if it is an HTML Element. (Returns
'' for comment nodes.)

=item nodeValue

This method returns undef unless the node is a comment. In most DOMs
this attribute contains the value for Text nodes (which are just
strings here).

=item getAttribute($attr)

Returns the value of the specified attribute.

=item setAttribute($attr, $value)

Sets the specified attribute to the given value.

=item removeAttribute($attr)

Removes the specified attribute.

=item hasAttributes

Returns 1 if the node has attributes. Otherwise returns 0.

=item id id($value)

Same as C<getAttribute('id')> or C<setAttribute('id', $value)>.

=item className className($value)

Same as C<getAttribute('class')> or C<setAttribute('class', $value)>.

=item parentNode

Returns the node's parent node.

=item childNodes

Returns a list of the node's child nodes.

=item firstChild

Returns the node's first child node. May be a string (aka a text node).

=item lastChild

Returns the node's last child node. May be a string (aka a text node).

=item appendChild($node)

Adds a node (or a string) to the end of the current node's children.

=back

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2008. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
