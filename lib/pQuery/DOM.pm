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
    $self->{'_no_space_compacting'}= 0;
    $self->{'_store_comments'}     = 0;
    $self->{'_store_declarations'} = 1;
    $self->{'_store_pis'}          = 0;
    $self->{'_p_strict'} = 0;

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
    my $dom = $class->_builder->parse_content($html);
    if ($html =~ /^\s*<html.*?>/) {
        return $dom;
    }
    my @dom = map {
        if (ref($_)) {
            delete $_->{_parent};
        }
        $_;
    } @{$dom->{_body}{_content}};
    return wantarray ? @dom : $dom[0];
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
    if (@_) {
        my $dom = $self->html_to_dom(@_);
        die "XXX - need to insert dom here";
    }

    my $html = '';

    my @list = @{$self->{_content}};
    for (@list) {
        _to_html($_, \$html);
    }

    return $html;
}

sub getElementsByTagName {
    die "Not yet implemented";
}

sub getElementById {
    die "Not yet implemented";
}

sub nodeType {
    return 1;
}

sub nodeName {
    return uc($_[0]->{_tag});
}

sub getAttribute {
    return $_[0]->{$_[1]};
}

sub setAttribute {
    die "Not yet implemented";
}

sub hasAttributes {
    die "Not yet implemented";
}

sub removeAttribute {
    die "Not yet implemented";
}

sub tagName {
    die "Not yet implemented";
}

sub className {
    $_[0]->getAttribute("class");
}

sub nodeValue {
    die "Not yet implemented";
}

sub parentNode {
    die "Not yet implemented";
}

sub childNodes {
    die "Not yet implemented";
}

sub firstChild {
    die "Not yet implemented";
}

sub lastChild {
    die "Not yet implemented";
}

sub previousSibling {
    die "Not yet implemented";
}

sub nextSibling {
    die "Not yet implemented";
}

sub attributes {
    die "Not yet implemented";
}


################################################################################
# Helper Functions
################################################################################
sub _to_html {
    my ($elem, $html) = @_;
    if (ref $elem) {
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
        for my $child (@{$elem->{_content}}) {
            _to_html($child, $html);
        }
        $$html .= '</' . $elem->{_tag} . '>';
    }
    else {
        $$html .= $elem;
    }
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

=head1 METHODS

The names of (most of) the pQuery::DOM methods are the same as their
JavaScript counterparts. However only a subset of the JavaScript DOM is
actually implemented.

=head2 Class Methods

=over

=item fromHTML($html)

This is the main constructor method. It takes any HTML string and returns the
DOM object tree that represents that HTML.

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

=item nodeName

This method returns the name of the node, which is the uppercase
HTML tag name.

=back

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2008. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
