use strict; use warnings;
package pQuery::DOM;

use Carp;

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

#------------------------------------------------------------------------------#
# pQuery::DOM Class Methods
#------------------------------------------------------------------------------#
sub fromHTML {
    my ($class, $html) = @_;
    my $dom;
    if ($html =~ /^\s*<html.*?>.*<\/html>\s*\z/is) {
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

#------------------------------------------------------------------------------#
# DOM Object Methods
#------------------------------------------------------------------------------#
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
    $tag = lc $tag;
    my $found = [];
    _find($self, $found, sub { $_->{_tag} eq $tag or $tag eq "*" });
    shift @$found if @$found and $found->[0] == $self;
    return $found;
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
    my $className = $_[0]->getAttribute("class");
    return defined $className
        ? $className
        : '';
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

sub firstChildRef {
    my $content = $_[0]->{_content} or return;
    for (my $i = 0; $i < @$content; $i++) {
        return $content->[$i] if ref $content->[$i];
    }
    return;
}

sub lastChildRef {
    my $content = $_[0]->{_content} or return;
    for (my $i = @$content - 1; $i >= 0; $i--) {
        return $content->[$i] if ref $content->[$i];
    }
    return;
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

sub nextSiblingRef {
    my $content = $_[0]->parentNode->{_content} or return;
    my $found = 0;
    for (my $i = 0; $i < @$content; $i++) {
        return $content->[$i] if $found and ref $content->[$i];
        $found = 1 if ref($content->[$i]) and $content->[$i] == $_[0];
    }
    return;
}

sub previousSiblingRef {
    my $content = $_[0]->parentNode->{_content} or return;
    my $found = 0;
    for (my $i = @$content - 1; $i >= 0; $i--) {
        return $content->[$i] if $found and ref $content->[$i];
        $found = 1 if ref($content->[$i]) and $content->[$i] == $_[0];
    }
    return;
}

sub nextSibling {
    die "pQuery::DOM does not support the nextSibling method";
}

sub attributes {
    die "pQuery::DOM::attributes not yet implemented";
}

#------------------------------------------------------------------------------#
# Common pQuery method mistakes
#------------------------------------------------------------------------------#
# sub text {
#     confess "Invalid method 'text' called on pQuery::DOM object";
# }

# self closing tags
my %selfclose = (
    "br" => 1,
    "hr" => 1,
    "input" => 1
);

#------------------------------------------------------------------------------#
# Helper Functions
#------------------------------------------------------------------------------#
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

    if (exists $selfclose{$elem->{_tag}})
    {
        $$html .= '/>';
    }
    else
    {
        $$html .= '>';
        for my $child (@{$elem->{_content} || []}) {
            _to_html($child, $html);
        }
        $$html .= '</' . $elem->{_tag} . '>';
    }
}
# XXX "work around vim hilight bug

sub _find {
    my ($elem, $found, $test) = @_;
    $_ = $elem;
    if (&$test()) {
        push @$found, $_;
    }

    map _find($_, $found, $test), grep ref($_), @{$elem->{_content} || []};
}

1;
