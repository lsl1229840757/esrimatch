package tk.piaoyang.ssm.controller;

import cn.itcast.common.utils.Page;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import tk.piaoyang.ssm.pojo.BaseDict;
import tk.piaoyang.ssm.pojo.Customer;
import tk.piaoyang.ssm.pojo.CustomerExample;
import tk.piaoyang.ssm.service.BaseDictService;
import tk.piaoyang.ssm.service.CustomerService;

import java.util.List;

@Controller
public class CustomerController {
    @Autowired
    BaseDictService baseDictService;
    @Autowired
    CustomerService customerService;

    // 客户来源
    @Value("${CUSTOMER_FROM_TYPE}")
    private String CUSTOMER_FROM_TYPE;
    // 客户行业
    @Value("${CUSTOMER_INDUSTRY_TYPE}")
    private String CUSTOMER_INDUSTRY_TYPE;
    // 客户级别
    @Value("${CUSTOMER_LEVEL_TYPE}")
    private String CUSTOMER_LEVEL_TYPE;

    @RequestMapping("/customer/list")
    public String list(Model model,
                       String custName, String custSource, String custIndustry, String custLevel,
                       @RequestParam(defaultValue = "1") Integer page,
                       @RequestParam(defaultValue = "10") Integer rows) {
        // 把前端页面需要显示的数据放到模型中
        List<BaseDict> fromType = this.baseDictService.queryBaseDictByDictTypeCode(this.CUSTOMER_FROM_TYPE);
        List<BaseDict> industryType = this.baseDictService.queryBaseDictByDictTypeCode(this.CUSTOMER_INDUSTRY_TYPE);
        List<BaseDict> levelType = this.baseDictService.queryBaseDictByDictTypeCode(this.CUSTOMER_LEVEL_TYPE);
        model.addAttribute("fromType", fromType);
        model.addAttribute("industryType", industryType);
        model.addAttribute("levelType", levelType);

        //创建查询条件
        CustomerExample customerExample = new CustomerExample();
        CustomerExample.Criteria criteria = customerExample.createCriteria();
        if(custName != null)
            criteria.andCustNameLike("%" + custName + "%");
        criteria.andCustSourceEqualTo(custSource);
        criteria.andCustIndustryEqualTo(custIndustry);
        criteria.andCustLevelEqualTo(custLevel);

        // 计算起始条目
        int start = (page - 1) * rows;

        customerExample.setStart(start);
        customerExample.setRows(rows);

        List<Customer> customerList = customerService.queryCustomerByQueryVo(customerExample);

        int total = customerService.countByExample(customerExample);

        // 分页查询数据
        Page<Customer> page_ = new Page<>(total, page, rows, customerList);

        // 把分页查询的结果放到模型中
        model.addAttribute("page", page_);

        // 数据回显
        model.addAttribute("custName", custName);
        model.addAttribute("custSource", custSource);
        model.addAttribute("custIndustry", custIndustry);
        model.addAttribute("custLevel", custLevel);

        return "customer";
    }
    @RequestMapping("/customer/edit")
    public @ResponseBody
    Customer edit(Integer id){
        return customerService.selectByPrimaryKey(id);
    }
    @RequestMapping("/customer/update")
    public @ResponseBody
    void update(Customer customer){
        customerService.updateByPrimaryKeySelective(customer);
    }
    @RequestMapping("/customer/delete")
    public @ResponseBody
    void delete(Integer id){
        customerService.deleteByPrimaryKey(id);
    }
}
