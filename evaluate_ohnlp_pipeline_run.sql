--Queries written against PostGreSQL; queries should be adaptable to other SQL DIALECTS
--OPTIONAL: indicates that query uses additional data stored in OHDSI
--ADVANCED: indicates uses PostGreSQL specific syntax/functions which would need to be rewritten

--Author: Janos Hajagos (jhajagos)

--Set the search path
set search_path to sbm_covid19_documents, sbm_covid19_hi_cdm_build;

--Get the count of notes
select count(note_id) as n_notes from note;

--OPTIONAL: Get counts for person and visit_occurrences
select count(note_id) as n_notes,
       count(distinct person_id) as n_person,
       count(distinct visit_occurrence_id) as n_visits
from note;


--Get the count of annotations that have been been made
select count(*) as n_annotations,
       count(distinct note_id) as n_notes,
       count(distinct lexical_variant) as n_lexical_variants,
       count(distinct note_nlp_concept_id) as n_concepts
from  note_nlp;


--OPTIONAL: Join to back to notes to get number of visits and persons with annotations
select count(*) as n_annotations,
       count(distinct nn.note_id) as n_notes,
       count(distinct lexical_variant) as n_lexical_variants,
       count(distinct note_nlp_concept_id) as n_concepts,
       count(distinct person_id) as n_person,
       count(distinct visit_occurrence_id) as n_visits
from  note_nlp nn join note n on nn.note_id = n.note_id;


--Get counts for note_nlp_concept_id across
select note_nlp_concept_id,
       count(*) as n_annotations,
       count(distinct note_id) as n_notes,
       count(distinct lexical_variant) as n_lexical_variants
from note_nlp group by note_nlp_concept_id order by count(*) desc;

--OPTIONAL: Join back to notes to get number of visits and number of options
select note_nlp_concept_id,
       count(*) as n_annotations,
       count(distinct nn.note_id) as n_notes,
       count(distinct lexical_variant) as n_lexical_variants,
       count(distinct person_id) as n_person,
       count(distinct visit_occurrence_id) as n_visits
from note_nlp nn join note n on nn.note_id = n.note_id
group by note_nlp_concept_id order by count(*) desc;

--OPTIONAL Join in concept table to get concept names
select note_nlp_concept_id,
       c.concept_name,
       count(*) as n_annotations,
       count(distinct nn.note_id) as n_notes,
       count(distinct lexical_variant) as n_lexical_variants,
       count(distinct person_id) as n_person,
       count(distinct visit_occurrence_id) as n_visits
from note_nlp nn join note n on nn.note_id = n.note_id
    left outer join concept c on c.concept_id = nn.note_nlp_concept_id
group by note_nlp_concept_id, c.concept_name order by count(*) desc;

--Get counts for which term modifiers match
select note_nlp_concept_id, term_modifiers,
       count(*) as n_annotations,
       count(distinct note_id) as n_notes,
       count(distinct lexical_variant) as n_lexical_variants
from note_nlp group by note_nlp_concept_id, term_modifiers order by note_nlp_concept_id, count(*) desc;


--OPTIONAL
select note_nlp_concept_id,
       c.concept_name,
       term_modifiers,
       count(*) as n_annotations,
       count(distinct nn.note_id) as n_notes,
       count(distinct lexical_variant) as n_lexical_variants,
       count(distinct person_id) as n_person,
       count(distinct visit_occurrence_id) as n_visits
from note_nlp nn join note n on nn.note_id = n.note_id
    left outer join concept c on c.concept_id = nn.note_nlp_concept_id
group by note_nlp_concept_id, term_modifiers, c.concept_name order by note_nlp_concept_id, count(*) desc;

--ADVANCED: Contains PostGreSQL (PSQL) specific functions
--Get positive and negative term counts
--Get top lexical variants
with note_nlp_enhanced as (
select
       split_part(split_part(term_modifiers, ',', 1), '=', 2) as certainty, --psql
       split_part(split_part(term_modifiers, ',', 2), '=', 2) as experiencr, --psql
       split_part(split_part(term_modifiers, ',', 3), '=', 2) as status, --psql
       length(snippet) as snippet_length, --psql
       length(lexical_variant) as lexical_variant_length, --psql
       nn.*
from note_nlp nn)
,
ranked_lexical_variants as
(
select z1.*, rank() over (partition by note_nlp_concept_id order by n_annotations desc) as lexical_variant_rank from (
       select lower(lexical_variant) as lower_lexical_variant, note_nlp_concept_id, count(*) as n_annotations
           from note_nlp_enhanced
       group by lower(lexical_variant), note_nlp_concept_id) z1
)
select
    nne1.note_nlp_concept_id,
    c.concept_name, c.vocabulary_id,
    c.concept_code,
    nne1.n_annotations,
    pos.n_annotations as pos_n_annotations,
    neg.n_annotations as neg_n_annotations,
    nne1.n_notes,
    pos.n_notes as pos_n_notes,
    neg.n_notes as neg_n_notes,
    nne1.n_lexical_variants,
    nne1.n_lower_lexical_variants,
    top_vars.top_five_lower_lexical_variants,
    nne1.average_lexical_variant_length,
    nne1.average_snippet_length
from (
    select
        note_nlp_concept_id,
        count(*) as n_annotations,
        count(distinct note_id) as n_notes,
        count(distinct lexical_variant) as n_lexical_variants,
        count(distinct lower(lexical_variant)) as n_lower_lexical_variants,
        avg(snippet_length) as average_snippet_length,
        avg(lexical_variant_length) as average_lexical_variant_length
     from note_nlp_enhanced  group by note_nlp_concept_id
    ) nne1
left outer join
    (select note_nlp_concept_id, count(*) as n_annotations, count(distinct note_id) as n_notes
        from note_nlp_enhanced
            where certainty = 'Positive' group by note_nlp_concept_id) pos -- positive mentions
    on nne1.note_nlp_concept_id = pos.note_nlp_concept_id
left outer join (
    select note_nlp_concept_id,
           array_agg(lower_lexical_variant) as top_five_lower_lexical_variants --psql
    from ranked_lexical_variants where lexical_variant_rank <= 5 group by note_nlp_concept_id
) top_vars --top lower cases lexical variants matched
    on nne1.note_nlp_concept_id = top_vars.note_nlp_concept_id
left outer join
    (select note_nlp_concept_id, count(*) as n_annotations, count(distinct note_id) as n_notes
        from note_nlp_enhanced where certainty = 'Negated' group by note_nlp_concept_id) neg --negative mentions
    on nne1.note_nlp_concept_id = neg.note_nlp_concept_id
left outer join concept c on c.concept_id = nne1.note_nlp_concept_id --get concept name and codes
order by nne1.n_annotations desc
;

