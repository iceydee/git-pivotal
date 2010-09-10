require 'commands/base'

module Commands
  class Pick < Base
  
    def type
      raise Error("must define in subclass")
    end
    
    def plural_type
      raise Error("must define in subclass")
    end
  
    def branch_suffix
      raise Error("must define in subclass")
    end
    
    def run!
      super

      msg = "Retrieving latest #{plural_type} from Pivotal Tracker"
      if options[:only_mine]
        msg += " for #{options[:full_name]}"
      end
      put "#{msg}..."
      
      unless stories
        put "No #{plural_type} available!"
        return 0
      end
    
      stories.each_with_index do |story, index|
        put "#{index}):"
        put "Story:  #{story.name}"
        put "URL:    #{story.url}"
        put "Labels: #{story.labels}"
        put ""
      end
      
      put ""
      put "Choose #{plural_type} [0]: ", false
      story_no = input.gets.chomp.to_i
      story_no = 0 if story_no == ""
      story = stories[story_no]
      
      put "Updating #{type} status in Pivotal Tracker..."
      if story.start!(:owned_by => options[:full_name])
    
        suffix = branch_suffix
        unless options[:quiet]
          put "Enter branch name (will be prepended by #{story.id}) [#{suffix}]: ", false
          suffix = input.gets.chomp
      
          suffix = "feature" if suffix == ""
        end

        branch = "#{story.id}-#{suffix}"
        if get("git branch").match(branch).nil?
          put "Creating #{branch} branch..."
          sys "git checkout -b #{branch}"
        end
    
        return 0
      else
        put "Unable to mark #{type} as started"
        
        return 1
      end
    end

  protected

    def stories
      conditions = { :story_type => type, :current_state => :unstarted }
      conditions[:owned_by] = options[:full_name] if options[:only_mine]
      @stories ||= project.stories.find(:conditions => { :story_type => type, :current_state => :unstarted }, :limit => 5)
    end
  end
end
