require 'spec_helper'

module Gitlab::Markdown
  describe CommitRangeReferenceFilter do
    include ReferenceFilterSpecHelper

    let(:project) { create(:project) }
    let(:commit1) { project.repository.commit }
    let(:commit2) { project.repository.commit("HEAD~2") }

    it 'requires project context' do
      expect { described_class.call('Commit Range 1c002d..d200c1', {}) }.
        to raise_error(ArgumentError, /:project/)
    end

    %w(pre code a style).each do |elem|
      it "ignores valid references contained inside '#{elem}' element" do
        exp = act = "<#{elem}>Commit Range #{commit1.id}..#{commit2.id}</#{elem}>"
        expect(filter(act).to_html).to eq exp
      end
    end

    context 'internal reference' do
      let(:reference) { "#{commit1.id}...#{commit2.id}" }
      let(:reference2) { "#{commit1.id}..#{commit2.id}" }

      it 'links to a valid two-dot reference' do
        doc = filter("See #{reference2}")

        expect(doc.css('a').first.attr('href')).
          to eq urls.namespace_project_compare_url(project.namespace, project, from: "#{commit1.id}^", to: commit2.id)
      end

      it 'links to a valid three-dot reference' do
        doc = filter("See #{reference}")

        expect(doc.css('a').first.attr('href')).
          to eq urls.namespace_project_compare_url(project.namespace, project, from: commit1.id, to: commit2.id)
      end

      it 'links with adjacent text' do
        doc = filter("See (#{reference}.)")
        expect(doc.to_html).to match(/\(<a.+>#{Regexp.escape(reference)}<\/a>\.\)/)
      end

      it 'ignores invalid issue IDs' do
        exp = act = "See #{commit1.id.reverse}...#{commit2.id}"

        expect(project).to receive(:valid_repo?).and_return(true)
        expect(project.repository).to receive(:commit).with(commit1.id.reverse)
        expect(filter(act).to_html).to eq exp
      end

      it 'includes a title attribute' do
        doc = filter("See #{reference}")
        expect(doc.css('a').first.attr('title')).to eq "Commits #{commit1.id} through #{commit2.id}"
      end

      it 'includes default classes' do
        doc = filter("See #{reference}")
        expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-commit_range'
      end

      it 'includes an optional custom class' do
        doc = filter("See #{reference}", reference_class: 'custom')
        expect(doc.css('a').first.attr('class')).to include 'custom'
      end

      it 'supports an :only_path option' do
        doc = filter("See #{reference}", only_path: true)
        link = doc.css('a').first.attr('href')

        expect(link).not_to match %r(https?://)
        expect(link).to eq urls.namespace_project_compare_url(project.namespace, project, from: commit1.id, to: commit2.id, only_path: true)
      end
    end

    # TODO (rspeicher): Remove or re-enable
    # context 'cross-project reference' do
    #   let(:namespace) { create(:namespace, name: 'cross-reference') }
    #   let(:project2)  { create(:project, namespace: namespace) }
    #   let(:commit1)   { project.repository.commit }
    #   let(:commit2)   { project.repository.commit("HEAD~2") }
    #   let(:reference) { "#{project2.path_with_namespace}@#{commit.id}" }

    #   it 'links to a valid reference' do
    #     doc = filter("See #{reference}")

    #     expect(doc.css('a').first.attr('href')).
    #       to eq urls.namespace_project_commit_url(project2.namespace, project2, commit.id)
    #   end

    #   it 'links with adjacent text' do
    #     doc = filter("Fixed (#{reference}.)")
    #     expect(doc.to_html).to match(/\(<a.+>#{Regexp.escape(reference)}<\/a>\.\)/)
    #   end

    #   it 'ignores invalid issue IDs on the referenced project' do
    #     exp = act = "Fixed #{project2.path_with_namespace}##{commit.id.reverse}"

    #     expect(filter(act).to_html).to eq exp
    #   end
    # end
  end
end
