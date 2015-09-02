module BoxstarterLibrary
  module Helper
    def check_process_tree(parent, attr, match)
      wmi = ::WIN32OLE.connect("winmgmts://") 
      check_process_tree_internal(wmi, parent, attr, match)   
    end

    def check_process_tree_internal(wmi, parent, attr, match)
      boxlog "***Looking for parents running as #{match} at pid #{parent}***"

      if parent.nil?
        boxlog "***No more parents. Finished looking for #{match} parents***"
        return nil 
      end

      parent_proc = wmi.ExecQuery("Select * from Win32_Process where ProcessID=#{parent}")
      
      if parent_proc.each.count == 0
        boxlog "***No process for pid #{parent}. Finished looking for #{match} parents***"
        return nil
      end

      proc = parent_proc.each.next

      result = proc.send(attr)
      if !result.nil? && result.downcase.include?(match)
        boxlog "***Found #{match} parent pid #{parent}...returning true***"
        return proc 
      end

      if proc.Name == 'services.exe'
        boxlog "***Proc was running #{proc.Name}...quitting since this is the effective trunk***"
        return nil
      end

      boxlog "***Proc was running #{proc.Name}...trying its parent***"
      return check_process_tree_internal(wmi, proc.ParentProcessID, attr, match)
    end

    def boxlog(msg = '')
      Chef::Log.send(node['boxstarter']['loglevel'])
    end

  end
end