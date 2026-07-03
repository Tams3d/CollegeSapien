export interface DepartmentOption {
  name: string;
  code: string;
}

// Mirrors app/lib/utils/department_constants.dart — keep in sync.
export const departments: DepartmentOption[] = [
  { name: "Computer Science and Engineering", code: "CSE" },
  { name: "Information Technology", code: "IT" },
  { name: "Artificial Intelligence and Data Science", code: "AIDS" },
  { name: "Artificial Intelligence and Machine Learning", code: "AIML" },
  { name: "Computer Science and Business Systems", code: "CSBS" },
  { name: "Cyber Security", code: "CYS" },
  { name: "Electronics and Communication Engineering", code: "ECE" },
  { name: "Electrical and Electronics Engineering", code: "EEE" },
  { name: "Electronics and Instrumentation Engineering", code: "EIE" },
  { name: "Mechanical Engineering", code: "MECH" },
  { name: "Civil Engineering", code: "CIVIL" },
  { name: "Chemical Engineering", code: "CHEM" },
  { name: "Biomedical Engineering", code: "BME" },
  { name: "Biotechnology", code: "BT" },
  { name: "Automobile Engineering", code: "AUTO" },
  { name: "Aeronautical Engineering", code: "AERO" },
  { name: "Food Technology", code: "FT" },
  { name: "Agricultural Engineering", code: "AGRI" },
  { name: "Robotics and Automation", code: "RA" },
  { name: "Internet of Things", code: "IOT" },
];
